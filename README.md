코드
import cv2
import mediapipe as mp

mp_hands = mp.solutions.hands
mp_draw = mp.solutions.drawing_utils

hands = mp_hands.Hands(
    static_image_mode=False,
    max_num_hands=2,
    min_detection_confidence=0.7,
    min_tracking_confidence=0.7
)

cap = cv2.VideoCapture(0)

def count_fingers(hand_landmarks, handedness):
    fingers = []

    lm = hand_landmarks.landmark

    #엄지
    if handedness == "Right":
        if lm[4].x < lm[3].x:
            fingers.append(1)
        else:
            fingers.append(0)
    else:
        if lm[4].x > lm[3].x:
            fingers.append(1)
        else:
            fingers.append(0)

    #나머지
    tips = [8, 12, 16, 20]
    pips = [6, 10, 14, 18]

    for tip, pip in zip(tips, pips):
        if lm[tip].y < lm[pip].y:
            fingers.append(1)
        else:
            fingers.append(0)

    return sum(fingers)


while True:
    ret, frame = cap.read()
    if not ret:
        break

    frame = cv2.flip(frame, 1)
    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    result = hands.process(rgb)

    command_text = ""
    finger_count = 0

    if result.multi_hand_landmarks and result.multi_handedness:

        for hand_landmarks, handedness in zip(
            result.multi_hand_landmarks,
            result.multi_handedness
        ):

            label = handedness.classification[0].label
            finger_count = count_fingers(hand_landmarks, label)

            mp_draw.draw_landmarks(frame, hand_landmarks, mp_hands.HAND_CONNECTIONS)

    if finger_count == 1:
        command_text = "start"
    elif finger_count == 2:
        command_text = "stop"
    elif finger_count == 3:
        command_text = "faster"
    elif finger_count == 4:
        command_text = "slower"
    else:
        command_text = ""
        
    if command_text:
        cv2.putText(
            frame,
            command_text,
            (50, 200),
            cv2.FONT_HERSHEY_SIMPLEX,
            3,
            (0, 0, 255),
            6
        )

    cv2.imshow("sex", frame)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()




논문?
\documentclass[journal]{IEEEtran}

\title{mediapipe와 OpenCV를 활용한 손 감지 기반 페달 제어 시스템}

\author{정연우}

\begin{document}

\section{abstract}
본 연군가 뭔가의 목적은 하체에 제약이 있는 운전자들의 편의성을 위한 손 감지 기반 페달 제어 시스템의 제작이다.
mediapipe의 손 감지 코드를 사용하였고 OpenCV의 이미지 처리 기능을 활용하였다.


\section{Introduction}

현재의 차량 운전에 있어 페달은 운전자가 가속과 감속을 조절하여 차량 속도를 제어하는 필수 안전 장치이다.하지만 하체에 제약이 있는 사용자에게는 이를 사용할 수 없어 운전이 불가능 하다. 따라서 나는 손 감지 기반 페달 제어 시스템을 만들어 사용 대상자들의 편의성을 향상시키고자 한다.
따라서 본 연구에서는 손 감지 기반 페달 제어 시스템의 가능성을 탐구하고자 한다.

\section{Literature Review}

손 감지 기술은 현실 세계와 디지털 세계의 상호작용에 큰 영햑을 끼쳤다. 손 동작은 비언어적 의사소통 방식으로 
1. 일상생활 및 가전 (스마트 홈)

\begin{itemize}
    \item 스마트 TV/가전 제어: 리모컨 없이 손동작으로 채널을 변경하거나, 에어컨/냉장고의 기능을 제어합니다.
    \item 제스처 인식 자동문/조명: 손짓으로 문을 열거나, 움직임을 감지하여 자동으로 조명이 켜지고 꺼지는 시스템입니다.
    \item 스마트폰 동작 제어: 폰을 흔들어 기능을 실행하거나, 얼굴 모션으로 영상을 조작하는 기능입니다. 블로그 +5
\end{itemize}
2. 게임 및 엔터테인먼트

\begin{itemize}
    \item 모션 컨트롤 게임: 닌텐도 위(Wii)나 Xbox 키넥트처럼 사용자의 팔 동작이나 몸의 움직임을 센서가 감지하여 게임 내 캐릭터를 조종합니다.
    \item VR/AR 체험: 가상현실(VR) 기기에서 손의 움직임을 실시간으로 인식하여 현실감 있는 상호작용을 제공합니다. 펀딩포유 +2
\end{itemize}
3. 헬스케어 및 운동 분석

\begin{itemize}
    \item 홈 피트니스/운동 분석: 카메라가 사용자의 운동 동작을 분석하여 정확한 자세를 가이드하거나, 운동 횟수(카운팅)를 측정합니다.
    \item 재활 훈련: 사용자의 신체 움직임을 추적하여 재활 운동의 정확도를 높이고 진행 상황을 모니터링합니다. 위키독스 +2
\end{itemize}
4. 산업 현장 및 안전

\begin{itemize}
    \item 로봇 제어: 사람이 손짓으로 로봇에게 작업을 명령하거나, 움직임을 따라 하도록 제어합니다.
    \item 작업자 안전 모니터링: 공장에서 작업자의 위험한 자세나 제한 구역 진입을 동작 인식 시스템이 감지하여 실시간 알림을 제공합니다. 위키독스 +3
\end{itemize}
5. 보안 및 모션 캡처

\begin{itemize}
    \item 보안 카메라: 움직임이 탐지되면 자동으로 촬영을 시작하여 침입자를 알리는 방범 시스템입니다.
    \item 모션 캡처(MoCap): 영화, 게임 제작 시 실제 사람의 미세한 관절 움직임을 3D 데이터로 변환하여 디지털 캐릭터에 입히는 기술입니다. 모션테크놀로지 +3

\end{itemize}
 등에 활용된다.

자동차 인터페이스 에서도 손 인식 기술을 적용하려는 연구가 있다. (아래부터 다 논문 있었는데 출처가 사라졌다 ㅜㅜ지피티 물어볼것.) +내용도

또한 Mediapipe를 사용한 모션 감지를 통한 연구도 있다.

이와 같은 기존 연구들을 바탕으로 본 연구에서는 손 인식 기술을 활용한 페달 시스템의 가능성을 탐구하고, 실제 자동차에 적용 가능한 시스템을 만들 것이다.

\section{Methods}

무엇을써야하는가

\section{Results}

손가락의 감지 코드는 MediaPipe 솔루션 가이드 | Google AI Edge의 Python용 손 랜드마크 감지 가이드를 사용했다.

#엄지 손가락 감지
오른손에서 thumb_tip.x < thumb_pip.x 라면 손가락이 펴져있다.
왼손에서 thumb_tip.x > thumb_pip.x 라면 손가락이 펴져있다.

#나머지 손가락 감지
tip.y < pip.y 라면 손가락이 펴져있다.

여기서 tip와 pip는 각각 손가락 가장 끝 쪽 마디, 손가락 가장 끝 쪽 관절을 의미한다.
이 알고리즘으로 펼쳐진 손가락의 개수를 알 수 있다.
이 구현은 Indriani & Agoes (2021)와 Gil-Martín et al. (2025)의 권고(랜드마크 기반 입력, 공간 정규화)와 일치한다.

#메인
손가락이 1개 펴져 있다면 'start' 이다.
손가락이 2개 펴져 있다면 'stop' 이다.
손가락이 3개 펴져 있다면 'faster' 이다.
손가락이 4개 펴져 있다면 'slower' 이다.

\section{Discussion}

본 연구는 MediaPipe로 손가락 개수 인식을 차량 제어에 적용하고 관련 선행 연구들을 근거로 제작했다. 단순히 손가락의 개수만으로 인식하기에 소수를  제외한 사지 중 일부가 없는 사람들이 편리하게 이용할 수  있다.

\section{Reference}
https://ai.google.dev/edge/mediapipe/solutions/vision/hand_landmarker/python?hl=ko


1.Amprimo, G., Masi, G., Pettiti, G., Olmo, G., Priano, L., & Ferraris, C. (2024). Hand tracking for clinical applications: Validation of the Google MediaPipe Hand (GMH) and GMH-D frameworks. Biomedical Signal Processing and Control, 96, 106508. 

2.Gil-Martín, M., Marini, M. R., Martín-Fernández, I., & Esteban-Romero, S. (2025). Hand gesture recognition using MediaPipe landmarks and deep learning networks. In Proceedings of ICAART 2025 (Vol. 3, pp. 24–30). INSTICC Press. 

3.Indriani, M. H., & Agoes, A. (2021). Applying hand gesture recognition for user guide application using MediaPipe. Advances in Engineering Research, 207, 297–301. 

4.Jalayer, R., Jalayer, M., Orsenigo, C., & Tomizuka, M. (2026). A review on deep learning for vision-based hand detection, hand segmentation and hand gesture recognition in human–robot interaction. Robotics and Computer-Integrated Manufacturing, 97, 103110. 

5.Huda, M. R., Ali, M. L., & Sadi, M. S. (2025). Developing a real-time hand-gesture recognition technique for wheelchair control. PLOS One, 20(4), e0319996. 

6.Sadi, M. S., Alotaibi, M., Islam, M. R., Islam, M. S., Alhmiedat, T., & Bassfar, Z. (2022). Finger-gesture controlled wheelchair with enabling IoT. Sensors, 22(24), 2107. 

7.Wameed, M., Alkamachi, A. M., & Ercelibi, E. (2023). Tracked robot control with hand gesture based on MediaPipe. Al-Khwarizmi Engineering Journal, 19(3), 56–71. 


8.Swain, B. K., & Bhoi, A. K. (2024). Single and multi-hand gesture based soft material robotic car control. Procedia Computer Science, 235, 3055–3064. 


9.Saravana, S. M. K., Lishan, C. L., Rao, S. P., & Manushree, K. B. (2025). A comprehensive survey on gesture-controlled interfaces: Technologies, applications, and challenges. International Journal of Scientific Research in Science and Technology, 12(2), 1112–1136. 


10.Rojas, M., Ponce, P., & Molina, A. (2022). Development of a sensing platform based on hands-free interfaces for controlling electronic devices. Frontiers in Human Neuroscience, 16, 867377.
 
11.Haddoun, A., Djabri, D., Saidani, M., & Benbouzid, M. (2025). Development and evaluation of a head-controlled wheelchair system for users with severe motor impairments. MethodsX, 15, 103485. 


12.Vysocký, A., Poštulka, T., Chlebek, J., Kot, T., Maslowski, J., & Grushko, S. (2023). Hand gesture interface for robot path definition in collaborative applications: Implementation and comparative study. Sensors, 23(9), 4219.

\end{document}
