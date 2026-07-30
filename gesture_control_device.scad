/*
  Raspberry Pi 3B+ Gesture Control Device enclosure
  Design basis: Raspberry Pi Camera Module V2, 5 mm LED output,
  2N2222 transistor circuit on a 20 x 40 mm perfboard.

  Units: millimetres. Select part below, then export that part as STL.
  Heat-set inserts are used so the enclosure can be opened repeatedly.
*/

// ---------- Customiser ----------
part = "assembly"; // [assembly,inspection,electronics,kiosk,hand,base,lid,camera_bezel,desk_stand,print_accessories]
show_references = true;
preview_quality = false;
show_labels = true;
cooling = "slots";            // [slots,fan30]
transistor_package = "TO92";  // [TO92,TO18] Verify the purchased 2N2222 package.
indicator_state = "detected"; // [off,detected,error] off=unlit, detected=red, error=blue

// ---------- Print/process parameters ----------
$fn = preview_quality ? 28 : 56;
eps = 0.05;
fit = 0.25;                 // FDM clearance; use 0.35 for a loose printer
wall = 2.4;
bottom_t = 2.4;
top_t = 2.4;
corner_r = 5;

// ---------- Enclosure envelope ----------
case_l = 126;
case_w = 86;
base_h = 20;
lid_h = 12;

// Raspberry Pi 3B+ nominal PCB (85 x 56 mm, M2.5 holes)
pi_l = 85;
pi_w = 56;
pi_x = case_l - wall - 2 - pi_l;  // USB/Ethernet connectors reach the right wall
pi_y = wall + 2;                  // power/HDMI connectors reach the front wall
pi_holes = [[3.5,3.5], [61.5,3.5], [3.5,52.5], [61.5,52.5]];
pi_post_d = 7.4;
pi_post_h = 5.5;
m25_insert_d = 3.5;               // Verify against the purchased insert
m25_insert_h = 4;

// Case closure: M3 x 20 CSK screws + 4 mm OD heat-set inserts
case_screw_d = 3.3;
case_insert_d = 4.0;
case_insert_h = 5;
case_boss_d = 8.0;
case_screws = [[7,7], [case_l-7,7], [7,case_w-7], [case_l-7,case_w-7]];

// Camera V2 nominal PCB and removable clamp bezel
cam_pcb_l = 25;
cam_pcb_w = 24;
cam_open_l = 21.2;
cam_open_w = 20.2;
cam_x = 82;
cam_y = 67;
cam_bezel_l = 34;
cam_bezel_w = 33;
cam_bezel_h = 4.2;
m2_clear_d = 2.35;
m2_insert_d = 3.2;
m2_insert_h = 3.5;
m2_boss_d = 6.4;
cam_screw_dx = 14.3;
cam_screw_dy = 13.4;

// Indicator LED and transistor perfboard bay. The LED is on the same
// user-facing lid surface as the camera, so gesture recognition is visible
// without opening the enclosure.
led_x = 57;
led_y = 67;
led_hole_d = 5.2;
perf_x = 6;
perf_y = 23;
perf_l = 27;
perf_w = 42;

// Optional 30 mm fan (24 mm square mounting-hole spacing, M3 clearance).
fan_x = 99;
fan_y = 37;
fan_open_d = 27;
fan_hole_spacing = 24;
fan_screw_d = 3.2;

// Alignment tubes make closing the compact enclosure repeatable before the
// four M3 lid screws are fitted.
alignment_points = [[pi_x-5,12], [pi_x-5,case_w-12]];

// ---------- Small geometry helpers ----------
module rounded_rect_2d(l, w, r) {
    hull() {
        translate([r,r]) circle(r=r);
        translate([l-r,r]) circle(r=r);
        translate([r,w-r]) circle(r=r);
        translate([l-r,w-r]) circle(r=r);
    }
}

module rounded_box(l, w, h, r=corner_r) {
    linear_extrude(height=h)
        rounded_rect_2d(l, w, min(r, min(l,w)/2));
}

module m3_countersunk_hole(h) {
    cylinder(d=case_screw_d, h=h+eps);
    translate([0,0,h-2.0])
        cylinder(d1=case_screw_d, d2=6.4, h=2.0+eps);
}

module pi_hole_posts() {
    for (p = pi_holes)
        translate([pi_x+p[0], pi_y+p[1], bottom_t])
            cylinder(d=pi_post_d, h=pi_post_h);
}

module case_bosses(h) {
    for (p = case_screws)
        translate([p[0],p[1],bottom_t])
            cylinder(d=case_boss_d, h=h-bottom_t);
}

module cam_bosses(h) {
    for (sx=[-1,1], sy=[-1,1])
        translate([cam_x + sx*cam_screw_dx, cam_y + sy*cam_screw_dy, 0])
            cylinder(d=m2_boss_d, h=h);
}

module cam_screw_holes(h) {
    for (sx=[-1,1], sy=[-1,1])
        translate([cam_x + sx*cam_screw_dx, cam_y + sy*cam_screw_dy, -eps])
            cylinder(d=m2_clear_d, h=h+2*eps);
}

module base_alignment_posts() {
    for (p = alignment_points)
        translate([p[0],p[1],base_h-2]) cylinder(d=4.0,h=5.5);
}

module lid_alignment_tubes() {
    for (p = alignment_points)
        translate([p[0],p[1],0]) cylinder(d=7.0,h=4.8);
}

module lid_alignment_pockets() {
    for (p = alignment_points)
        translate([p[0],p[1],-eps]) cylinder(d=4.5,h=4.9+eps);
}

// ---------- Base: Pi, perfboard and heat-set inserts ----------
module perfboard_guides() {
    // A 20 x 40 mm protoboard slides between rails; secure it with zip ties.
    translate([perf_x, perf_y, bottom_t]) cube([2, perf_w, 2.3]);
    translate([perf_x+perf_l-2, perf_y, bottom_t]) cube([2, perf_w, 2.3]);
    translate([perf_x, perf_y, bottom_t]) cube([perf_l, 2, 2.3]);
    translate([perf_x, perf_y+perf_w-2, bottom_t]) cube([perf_l, 2, 2.3]);
}

// Two cable-tie slots directly behind the front I/O opening hold the Pi's
// power lead against accidental pulls. Use a 2.5 mm zip tie after wiring.
module power_cable_tie_slots() {
    for (xx=[pi_x+8, pi_x+22])
        translate([xx, wall+1.5, -eps]) cube([2.8, 6.5, bottom_t+2*eps]);
}

// U-shaped guide prevents the Camera V2 FFC from touching sharp edges or
// wandering into the fan/vent area while it bends down to the CSI connector.
module ffc_cable_guide() {
    guide_y = 56;
    guide_h = 11;
    translate([cam_x-10, guide_y, bottom_t]) cube([2, 11, guide_h]);
    translate([cam_x+8, guide_y, bottom_t]) cube([2, 11, guide_h]);
    translate([cam_x-10, guide_y, bottom_t]) cube([20, 2, 2]);
}

// A low partition protects the transistor perfboard and its wiring from the
// Pi PCB while preserving access through the left-side service aperture.
module perfboard_protection() {
    translate([perf_x+perf_l+1,perf_y,bottom_t]) cube([1.8,perf_w,11]);
    translate([perf_x,perf_y+perf_w-2,bottom_t]) cube([perf_l+2.8,2,6]);
}

module base() {
    difference() {
        union() {
            difference() {
                rounded_box(case_l, case_w, base_h);
                translate([wall, wall, bottom_t])
                    cube([case_l-2*wall, case_w-2*wall, base_h-bottom_t+eps]);
            }
            case_bosses(base_h);
            pi_hole_posts();
            perfboard_guides();
            ffc_cable_guide();
            perfboard_protection();
            base_alignment_posts();
        }

        // Pi micro-USB / HDMI / audio edge. Wide opening suits cable variants.
        translate([pi_x-1, -eps, 5.0])
            cube([pi_l+2, wall+2*eps, 14.5]);

        // Pi four USB ports and Ethernet jack.
        translate([case_l-wall-eps, pi_y+1, 4.0])
            cube([wall+2*eps, pi_w-2, 17.5]);

        // Service aperture for the small transistor/terminal board.
        translate([-eps, perf_y+3, 5])
            cube([wall+2*eps, perf_w-6, 14]);

        // M3 closure insert pockets: heat-set from the open top of the base.
        for (p = case_screws)
            translate([p[0],p[1],base_h-case_insert_h])
                cylinder(d=case_insert_d, h=case_insert_h+eps);

        // Pi M2.5 inserts: heat-set from above, then screw Pi down from above.
        for (p = pi_holes)
            translate([pi_x+p[0],pi_y+p[1],bottom_t+pi_post_h-m25_insert_h])
                cylinder(d=m25_insert_d, h=m25_insert_h+eps);

        // Zip-tie slots avoid assuming a particular perfboard hole pattern.
        for (yy=[perf_y+7, perf_y+perf_w-14]) {
            translate([perf_x+5, yy, -eps]) cube([2.8, 7, bottom_t+2*eps]);
            translate([perf_x+perf_l-7.8, yy, -eps]) cube([2.8, 7, bottom_t+2*eps]);
        }
        power_cable_tie_slots();
    }
}

// ---------- Lid: camera pocket, LED hole, airflow ----------
module ventilation_slots() {
    // Directly above the Pi SoC area; long slots retain top-panel stiffness.
    for (i=[0:5])
        translate([86+i*4.2, 23, lid_h-top_t-eps])
            cube([2.2, 28, top_t+2*eps]);
}

module cooling_opening() {
    if (cooling == "fan30") {
        translate([fan_x, fan_y, lid_h-top_t-eps])
            cylinder(d=fan_open_d, h=top_t+2*eps);
        for (sx=[-1,1], sy=[-1,1])
            translate([fan_x+sx*fan_hole_spacing/2,
                       fan_y+sy*fan_hole_spacing/2,
                       lid_h-top_t-eps])
                cylinder(d=fan_screw_d, h=top_t+2*eps);
    } else
        ventilation_slots();
}

// Raised labels are printed as part of the lid; they make the orientation and
// indicator function immediately clear in a classroom demonstration.
module lid_labels() {
    translate([43,16,lid_h])
        linear_extrude(height=0.45)
            text("GESTURE", size=4.3, halign="center", valign="center");
    translate([56,58,lid_h])
        linear_extrude(height=0.45)
            text("STATUS", size=3.0, halign="center", valign="center");
    translate([111,73,lid_h])
        linear_extrude(height=0.45)
            text("CAM", size=3.0, halign="center", valign="center");
}

module lid() {
    difference() {
        union() {
            difference() {
                rounded_box(case_l, case_w, lid_h);
                translate([wall,wall,-eps])
                    cube([case_l-2*wall, case_w-2*wall, lid_h-top_t+eps]);
            }
            // Camera bezel insert bosses are accessible from below.
            cam_bosses(lid_h-top_t);
            lid_alignment_tubes();
            if (show_labels) lid_labels();
        }

        // Countersunk M3 closure holes.
        for (p = case_screws)
            translate([p[0],p[1],-eps]) m3_countersunk_hole(lid_h+2*eps);
        lid_alignment_pockets();

        // Camera board opening. The perimeter supports the Camera V2 PCB;
        // the 15-pin FFC connector and cable pass through into the enclosure.
        translate([cam_x-cam_open_l/2, cam_y-cam_open_w/2, -eps])
            cube([cam_open_l,cam_open_w,lid_h+2*eps]);

        // M2 path and insert pocket for the removable camera bezel.
        cam_screw_holes(lid_h);
        for (sx=[-1,1], sy=[-1,1])
            translate([cam_x + sx*cam_screw_dx, cam_y + sy*cam_screw_dy, -eps])
                cylinder(d=m2_insert_d, h=m2_insert_h+eps);

        // External 5 mm status LED, beside the camera in the user's view.
        translate([led_x,led_y,-eps]) cylinder(d=led_hole_d, h=lid_h+2*eps);

        cooling_opening();
    }
}

// ---------- External camera clamp bezel ----------
module camera_bezel() {
    difference() {
        rounded_box(cam_bezel_l, cam_bezel_w, cam_bezel_h, 3);

        // The board rests on the lid; this rim clamps its edges.
        translate([(cam_bezel_l-cam_pcb_l-fit)/2,
                   (cam_bezel_w-cam_pcb_w-fit)/2, -eps])
            cube([cam_pcb_l+fit, cam_pcb_w+fit, 1.9+eps]);

        // Lens clearance. Camera V2 lens OD differs slightly by revision.
        translate([cam_bezel_l/2, cam_bezel_w/2, -eps])
            cylinder(d=11.0, h=cam_bezel_h+2*eps);

        for (sx=[-1,1], sy=[-1,1])
            translate([cam_bezel_l/2 + sx*cam_screw_dx,
                       cam_bezel_w/2 + sy*cam_screw_dy, -eps])
                cylinder(d=m2_clear_d, h=cam_bezel_h+2*eps);
    }
}

// Small press-in collar for a bare 5 mm LED; use PETG for repeated removal.
module led_bezel() {
    difference() {
        cylinder(d=8.4, h=2.0);
        translate([0,0,-eps]) cylinder(d=5.0, h=2.0+2*eps);
    }
}

// ---------- Tool-free desktop stand ----------
// Supports the complete case at about 55 degrees, directing the camera toward
// a seated or standing user instead of the ceiling. Print upright with a brim.
module stand_side_raw() {
    difference() {
        linear_extrude(height=6)
            polygon(points=[[-0,0],[-0,72],[-80,56],[-80,50],[-8,3]]);
        translate([0,0,-eps])
            linear_extrude(height=6+2*eps)
                polygon(points=[[-9,10],[-9,59],[-64,48],[-64,42],[-16,12]]);
    }
}

module desk_stand() {
    // Rails are just outside the case sidewalls; crossbars make one rigid part.
    translate([-6,0,-2]) rotate([0,90,0]) stand_side_raw();
    translate([case_l,0,-2]) rotate([0,90,0]) stand_side_raw();
    translate([-6,0,-2]) cube([case_l+12, 72, 4]); // joins rails and provides a flat print bed
    translate([-6,0,0]) cube([case_l+12, 7, 8]);
    translate([-6,64,0]) cube([case_l+12, 7, 8]);
    translate([-6,3,0]) cube([case_l+12, 5, 18]); // low stop prevents forward sliding
}

// ---------- Reference-only electronics (not printed) ----------
// These models make the completed invention readable in `assembly` view.
// They also reserve real spatial volume for every component named in §3.1.
module pi_reference() {
    color([0.05,0.42,0.16,0.55]) {
        translate([pi_x,pi_y,bottom_t+pi_post_h]) cube([pi_l,pi_w,1.6]);
        translate([pi_x+4,pi_y-2,bottom_t+pi_post_h]) cube([60,4,12]);
        translate([pi_x+pi_l-2,pi_y+2,bottom_t+pi_post_h]) cube([4,52,16]);
    }
}

module camera_reference() {
    color([0.03,0.38,0.16,0.55])
        translate([cam_x-cam_pcb_l/2,cam_y-cam_pcb_w/2,base_h+lid_h])
            cube([cam_pcb_l,cam_pcb_w,1.6]);
    color([0.1,0.1,0.1,0.7])
        translate([cam_x,cam_y,base_h+lid_h]) cylinder(d=8.5,h=5);
}

// Simple rounded TO-92 envelope for the 2N2222 NPN transistor. Its flat
// face is directed toward the service opening so the circuit can be checked.
module transistor_2n2222_reference() {
    tx = perf_x + 10;
    ty = perf_y + 11;
    tz = bottom_t + 1.6;
    if (transistor_package == "TO18")
        color("silver") translate([tx,ty,tz]) cylinder(d=5.8, h=4.8);
    else
        color([0.08,0.08,0.08])
            translate([tx,ty,tz])
                difference() {
                    cylinder(d=5.2, h=5.1);
                    translate([-3,-3,-eps]) cube([2.1,6,5.1+2*eps]);
                }
    // Collector, base and emitter leads pass through the perfboard.
    color("silver")
        for (xoff=[-1.25,0,1.25])
            translate([tx+xoff,ty-1.6,tz-3.1]) cylinder(d=0.55,h=3.3);
}

// Axial resistor, including leads. The colour bands distinguish the 330 ohm
// LED current-limiting resistor from the GPIO base resistor.
module axial_resistor_reference(pos=[0,0,0], band_type="330") {
    band_colours = band_type == "330"
        ? [[0.95,0.35,0.05],[0.95,0.35,0.05],[0.34,0.16,0.05]]  // orange-orange-brown
        : [[0.34,0.16,0.05],[0.06,0.06,0.06],[0.85,0.05,0.05]]; // brown-black-red = 1 kΩ
    translate(pos) {
        color("silver") rotate([0,90,0]) cylinder(d=0.5,h=16,center=true);
        color([0.76,0.63,0.42]) rotate([0,90,0]) cylinder(d=2.25,h=8.5,center=true);
        for (i=[0:2])
            color(band_colours[i])
                translate([[-2.0,-0.6,0.8][i],0,0])
                    rotate([0,90,0]) cylinder(d=2.32,h=0.42,center=true);
    }
}

module led_5mm_reference() {
    // One 5 mm red/blue bi-colour indicator: off is translucent grey,
    // successful recognition is red, and an error state is blue.
    led_colour = indicator_state == "error" ? [0.04,0.18,0.95,0.9]
               : indicator_state == "detected" ? [0.9,0.03,0.03,0.9]
               : [0.28,0.28,0.28,0.55];
    color(led_colour) {
        translate([led_x,led_y,base_h+lid_h-2.2]) cylinder(d=4.9,h=3.2);
        translate([led_x,led_y,base_h+lid_h+1.0]) sphere(d=4.9);
    }
    color("silver")
        for (xoff=[-1.27,1.27])
            translate([led_x+xoff,led_y,base_h-2]) cylinder(d=0.52,h=lid_h+1);
}

module perfboard_reference() {
    // 20 x 40 mm protoboard, retained by the printed rails in the base.
    color([0.55,0.34,0.12,0.72])
        translate([perf_x+3.5,perf_y+1,bottom_t]) cube([20,40,1.6]);

    // Required circuit: 2N2222 and the 330 ohm LED current limiter.
    transistor_2n2222_reference();
    axial_resistor_reference([perf_x+15,perf_y+24,bottom_t+3.0],"330");

    // A 1 kohm base resistor is included because it protects the Pi GPIO.
    axial_resistor_reference([perf_x+15,perf_y+34,bottom_t+3.0],"1k");

    // Schematic-style insulated hookup wires show the actual switching path:
    // Pi GPIO -> base resistor -> 2N2222 -> LED/330 ohm -> 5 V.
    color([0.15,0.2,0.85,0.8])
        translate([pi_x+11,pi_y+45,bottom_t+7]) rotate([0,90,0]) cylinder(d=1.05,h=57);
    color([0.95,0.08,0.08,0.8])
        translate([perf_x+15,perf_y+24,bottom_t+5.1]) rotate([90,0,0]) cylinder(d=0.9,h=22);
}

module ffc_cable_reference(lid_lift=0) {
    // Flat-flex cable from Camera V2 to the Raspberry Pi CSI connector.
    color([0.92,0.88,0.62,0.68])
        hull() {
            translate([cam_x-7.5,cam_y-10,base_h-1+lid_lift]) cube([15,1.2,1.0]);
            translate([pi_x+43,pi_y+53,bottom_t+pi_post_h+2]) cube([15,1.2,1.0]);
        }
}

module assembly() {
    color("gainsboro") base();
    color("ivory") translate([0,0,base_h]) lid();
    color("black")
        translate([cam_x-cam_bezel_l/2,cam_y-cam_bezel_w/2,base_h+lid_h])
            camera_bezel();
    color("orange") translate([led_x,led_y,base_h+lid_h]) led_bezel();
    if (show_references) {
        pi_reference();
        camera_reference();
        perfboard_reference();
        led_5mm_reference();
        ffc_cable_reference();
    }
}

// Non-printing inspection view: the lid is lifted to expose the Pi and the
// complete transistor/LED circuit while preserving their installed positions.
module inspection() {
    color("gainsboro") base();
    if (show_references) {
        pi_reference();
        perfboard_reference();
        ffc_cable_reference(30);
    }
    translate([0,0,30]) {
        color("ivory") translate([0,0,base_h]) lid();
        color("black")
            translate([cam_x-cam_bezel_l/2,cam_y-cam_bezel_w/2,base_h+lid_h])
                camera_bezel();
        color("orange") translate([led_x,led_y,base_h+lid_h]) led_bezel();
        if (show_references) {
            camera_reference();
            led_5mm_reference();
        }
    }
}

// Component-only view: no enclosure, lid, stand, or printed fittings.
module electronics() {
    pi_reference();
    camera_reference();
    perfboard_reference();
    led_5mm_reference();
    ffc_cable_reference();
}

// Reference kiosk: the completed device is mounted as an inclined, user-facing
// gesture-control panel on a freestanding pedestal. This is a presentation
// view, not a separate print part.
module kiosk_pedestal() {
    color([0.22,0.24,0.28]) {
        translate([-25,-82,0]) rounded_box(180,140,8,8);
        translate([42,18,8]) rounded_box(46,24,76,5);
        translate([28,10,8]) cube([74,40,11]);
    }
}

module kiosk() {
    kiosk_pedestal();
    translate([0,33,19]) rotate([70,0,0]) assembly();
}

// Reference-only hand geometry for the gesture-recognition demonstration.
// It is a separate `part` and is not an enclosure print component.
module hand() {
    color([0.92,0.62,0.42]) {
        translate([-26,0,0]) rotate([90,0,0]) rounded_box(52,52,8,9);
        for (finger=[[-21,9,32],[-11,9,40],[0,10,46],[11,9,39],[21,8,30]])
            translate([finger[0]-finger[1]/2,0,47]) rotate([90,0,0])
                rounded_box(finger[1],finger[2],8,finger[1]/2);
        translate([-38,-1,24]) rotate([0,0,-38]) rotate([90,0,0])
            rounded_box(12,31,8,6);
    }
}

module print_accessories() {
    camera_bezel();
    translate([42,5,0]) led_bezel();
}

// ---------- Output selector ----------
if (part == "base")
    base();
else if (part == "lid")
    lid();
else if (part == "camera_bezel")
    camera_bezel();
else if (part == "desk_stand")
    desk_stand();
else if (part == "print_accessories")
    print_accessories();
else if (part == "inspection")
    inspection();
else if (part == "electronics")
    electronics();
else if (part == "kiosk")
    kiosk();
else if (part == "hand")
    hand();
else
    assembly();
