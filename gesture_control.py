from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path

import cv2
import mediapipe as mp
import numpy as np


GRID_ROWS = 6
GRID_COLS = 8
LANDMARK_THRESHOLD = 0.025
GRID_THRESHOLD = 0.060


@dataclass
class GestureTemplate:
    command: str
    grid_feature: np.ndarray
    landmark_feature: np.ndarray


def normalized_landmarks(hand_landmarks: object) -> np.ndarray:
    points = np.array(
        [[point.x, point.y, point.z] for point in hand_landmarks.landmark], dtype=np.float32
    )
    points -= points[0]
    scale = np.max(np.linalg.norm(points[:, :2], axis=1))
    if scale > 1e-6:
        points /= scale
    return points


def grid_feature(hand_landmarks: object, frame_shape: tuple[int, ...]) -> np.ndarray:
    height, width = frame_shape[:2]
    points = np.array(
        [[int(point.x * width), int(point.y * height)] for point in hand_landmarks.landmark],
        dtype=np.int32,
    )

    mask = np.zeros((height, width), dtype=np.uint8)
    hull = cv2.convexHull(points)
    cv2.fillConvexPoly(mask, hull, 255)
    small_mask = cv2.resize(mask, (GRID_COLS, GRID_ROWS), interpolation=cv2.INTER_AREA)
    occupancy = (small_mask.astype(np.float32) / 255.0).reshape(-1)

    direction = points[9].astype(np.float32) - points[0].astype(np.float32)
    angle = float(np.arctan2(direction[1], direction[0]))
    orientation = np.array([np.sin(angle), np.cos(angle)], dtype=np.float32)
    return np.concatenate((occupancy, orientation))


def landmark_error(template: np.ndarray, current: np.ndarray) -> float:
    return float(np.mean(np.square(template - current)))


def grid_error(template: np.ndarray, current: np.ndarray) -> float:
    grid_length = GRID_ROWS * GRID_COLS
    occupancy_error = np.mean(np.square(template[:grid_length] - current[:grid_length]))
    orientation_error = np.mean(np.square(template[grid_length:] - current[grid_length:]))
    return float(0.8 * occupancy_error + 0.2 * orientation_error)


def save_templates(path: Path, templates: list[GestureTemplate]) -> None:
    if not templates:
        return
    np.savez_compressed(
        path,
        commands=np.asarray([item.command for item in templates], dtype=np.str_),
        grid=np.stack([item.grid_feature for item in templates]),
        landmarks=np.stack([item.landmark_feature for item in templates]),
    )
    print(f"{len(templates)}개 손동작을 {path}에 저장했습니다.")


def load_templates(path: Path) -> list[GestureTemplate]:
    if not path.exists():
        return []
    with np.load(path, allow_pickle=False) as saved:
        commands = saved["commands"]
        grids = saved["grid"]
        landmarks = saved["landmarks"]
    templates = [
        GestureTemplate(str(command), grid, landmark)
        for command, grid, landmark in zip(commands, grids, landmarks, strict=True)
    ]
    print(f"{len(templates)}개 등록 손동작을 {path}에서 불러왔습니다.")
    return templates


def best_match(
    templates: list[GestureTemplate],
    current_grid: np.ndarray,
    current_landmarks: np.ndarray,
    algorithm: int,
) -> tuple[str | None, float, float]:
    if algorithm == 1:
        errors = [grid_error(item.grid_feature, current_grid) for item in templates]
        threshold = GRID_THRESHOLD
    else:
        errors = [landmark_error(item.landmark_feature, current_landmarks) for item in templates]
        threshold = LANDMARK_THRESHOLD

    index = int(np.argmin(errors))
    return templates[index].command, float(errors[index]), threshold


def draw_text(frame: np.ndarray, text: str, position: tuple[int, int], color: tuple[int, int, int]) -> None:
    cv2.putText(frame, text, position, cv2.FONT_HERSHEY_SIMPLEX, 0.62, color, 2, cv2.LINE_AA)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="MediaPipe 기반 비접촉 손동작 제어")
    parser.add_argument("--camera", type=int, default=0, help="OpenCV 카메라 번호 (기본값: 0)")
    parser.add_argument("--register", type=int, default=0, help="새로 등록할 손동작 개수")
    parser.add_argument("--templates", type=Path, default=Path("gesture_templates.npz"))
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    templates = load_templates(args.templates)
    to_register = args.register
    recognition_active = False
    algorithm = 2
    stable_command: str | None = None
    stable_count = 0
    displayed_command: str | None = None
    recent_landmarks: list[np.ndarray] = []
    recent_grids: list[np.ndarray] = []

    cap = cv2.VideoCapture(args.camera)
    if not cap.isOpened():
        raise RuntimeError(f"카메라 {args.camera}를 열 수 없습니다.")
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)

    mp_hands = mp.solutions.hands
    drawing = mp.solutions.drawing_utils
    print("Enter: 손동작 등록 | b: 인식 시작/중지 | 1/2: 알고리즘 선택 | q: 종료")

    try:
        with mp_hands.Hands(
            static_image_mode=False,
            max_num_hands=1,
            min_detection_confidence=0.70,
            min_tracking_confidence=0.60,
        ) as hands:
            while cap.isOpened():
                ok, frame = cap.read()
                if not ok:
                    break
                frame = cv2.flip(frame, 1)

                filtered = cv2.GaussianBlur(frame, (5, 5), 0)
                result = hands.process(cv2.cvtColor(filtered, cv2.COLOR_BGR2RGB))
                current_grid = None
                current_landmarks = None

                if result.multi_hand_landmarks:
                    hand = result.multi_hand_landmarks[0]
                    drawing.draw_landmarks(frame, hand, mp_hands.HAND_CONNECTIONS)
                    current_landmarks = normalized_landmarks(hand)
                    current_grid = grid_feature(hand, frame.shape)
                    recent_landmarks.append(current_landmarks)
                    recent_grids.append(current_grid)
                    recent_landmarks = recent_landmarks[-15:]
                    recent_grids = recent_grids[-15:]

                draw_text(frame, f"Algorithm {algorithm}  |  templates: {len(templates)}", (10, 28), (255, 255, 255))

                if to_register > 0:
                    draw_text(frame, f"Registration remaining: {to_register}  (Enter)", (10, 56), (0, 165, 255))
                elif recognition_active:
                    draw_text(frame, "Recognizing", (10, 56), (0, 255, 0))
                    if current_grid is not None and templates:
                        command, error, threshold = best_match(
                            templates, current_grid, current_landmarks, algorithm
                        )
                        draw_text(frame, f"error: {error:.4f} / {threshold:.4f}", (10, 84), (255, 255, 255))
                        if error < threshold:
                            if command == stable_command:
                                stable_count += 1
                            else:
                                stable_command, stable_count = command, 1
                            if stable_count >= 3:
                                displayed_command = command
                                draw_text(frame, f"DETECTED: {command}", (30, 160), (255, 0, 0))
                        else:
                            stable_command, stable_count = None, 0
                    if displayed_command is not None:
                        draw_text(frame, f"LAST RESULT: {displayed_command}", (30, 190), (255, 0, 0))
                else:
                    draw_text(frame, "Press b to recognize", (10, 56), (0, 165, 255))

                cv2.imshow("Gesture Control System", frame)
                key = cv2.waitKey(1) & 0xFF

                if key == ord("q"):
                    break
                if key == ord("1"):
                    algorithm = 1
                    print("알고리즘 1")
                elif key == ord("2"):
                    algorithm = 2
                    print("알고리즘 2")
                elif key == ord("b") and to_register == 0:
                    recognition_active = not recognition_active
                    stable_command, stable_count = None, 0
                    displayed_command = None
                    print("인식을 시작합니다." if recognition_active else "인식을 중지했습니다.")
                elif key in (10, 13) and to_register > 0:
                    if not recent_landmarks:
                        print("손을 카메라에 인식시킨 뒤 다시 Enter를 누르세요.")
                        continue
                    command = input("이 손동작에 연결할 명령 이름: ").strip()
                    if not command:
                        print("빈 명령은 등록하지 않습니다.")
                        continue
                    templates.append(
                        GestureTemplate(
                            command=command,
                            grid_feature=np.median(np.stack(recent_grids), axis=0),
                            landmark_feature=np.median(np.stack(recent_landmarks), axis=0),
                        )
                    )
                    to_register -= 1
                    print(f"'{command}' 등록 완료. 남은 개수: {to_register}")
                    if to_register == 0:
                        save_templates(args.templates, templates)
    finally:
        cap.release()
        cv2.destroyAllWindows()


if __name__ == "__main__":
    main()
