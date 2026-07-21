# UAV PX4 DDS install script update

- Date: 2026-07-21
- Workspace: `/home/c/BoomBoomFly`
- Target: `Scripts/installation/uav_px4_dds_install.sh`
- Execution policy: audit and dry-run only; no repository was cloned, fetched, checked out, reset, cleaned, moved, committed, or pushed.

## 1. Current `src/` composition

The workspace contains:

- 21 top-level source directories.
- 19 independent Git repositories.
- 79 `package.xml` manifests; `colcon list --base-paths src` discovers 77 packages because ignored/test manifests are not all listed.
- 2 local-only ROS packages without Git metadata: `cv_yolo_paddle_pkg` and `opencv_cpp`.
- 9 dirty repositories and 4 detached repositories.

Functional groups:

| Group | Repositories/packages |
|---|---|
| Flight control and launch | `offboard_cpp`, `offboard_py`, `px4_bringup`, `vision_to_mavros` |
| PX4/MAVLink/DDS | `mavlink`, `mavros`; managed additions `px4_msgs`, `Micro-XRCE-DDS-Agent` |
| Serial and hardware I/O | `serial-ros2`, `serial_driver_ros2`, `rplidar_ros` |
| Vision and camera | `librealsense`, `realsense-ros`, `vision_opencv`, local `opencv_cpp`, local `cv_yolo_paddle_pkg` |
| Navigation and SLAM | `navigation2`, `navigation_msgs`, `slam_toolbox`, `rtabmap`, `rtabmap_ros`, `imu_tools` |
| Simulation | `gazebo_ros_pkgs` |

The full repository table, branch/commit/dirty/detached state, and all requested manifest fields are in [`src_dependency_inventory.md`](src_dependency_inventory.md).

## 2. Download list changes

The old script managed only eight entries and did not match the current workspace. It also referenced stale paths (`vision_to_dds`, `serial_driver_ros`) and used PX4 message/RealSense versions different from the audited target.

Newly managed current-workspace repositories:

| Repository | Ref strategy | Reason |
|---|---|---|
| `gazebo_ros_pkgs` | audited SHA | Gazebo Classic ROS integration |
| `imu_tools` | tag `2.0.3` | IMU filters and RViz plugin |
| `mavlink` | release tag | MAVROS build dependency |
| `mavros` | tag `2.7.0` | PX4 MAVLink bridge |
| `navigation2` | audited SHA | Foxy navigation stack |
| `navigation_msgs` | tag `2.0.2` | Foxy navigation interfaces |
| `ros2_foxy_vision_to_mavros` | `main` | T265 pose bridge; replaces stale `vision_to_dds` entry |
| `rplidar_ros` | audited SHA | Laser driver |
| `rtabmap` | tag `0.21.1-foxy` | RTAB-Map core |
| `rtabmap_ros` | tag `0.21.1-foxy` | ROS wrappers and SLAM nodes |
| `serial-ros2` | audited SHA | `serial_driver` library dependency |
| `serial_driver_ros2` | `main` | Actual current serial repository; replaces stale `serial_driver_ros` |
| `slam_toolbox` | audited SHA | Foxy mapping |
| `vision_opencv` | tag `3.0.7` | `cv_bridge` and vision interfaces |

Corrected retained entries:

- `px4_msgs`: `v1.16.1` → `v1.16.2`.
- `Micro-XRCE-DDS-Agent`: floating default branch → `v2.4.2`, matching ROS 2 Foxy/Fast DDS 2.0.x guidance.
- `librealsense`: `v2.53.1` → audited current `v2.50.0`.
- `offboard_cpp` and `px4_bringup`: URL normalized from the current recorded remotes. Their local branch is `master`, but the remote no longer advertises it, so the verified current SHA is used.

`offboard_py` was not retained in the automated download list. Its recorded remote currently returns `Repository not found`; keeping it would violate the requirement to avoid erroneous repositories.

The requested check name `serial_driver_ros` does not exist in the current manifests. The repository directory is `serial_driver_ros2`, while its `package.xml` name (and therefore its `colcon list` name) is `serial_driver`; the script checks the factual package name.

## 3. Version strategy

- PX4/DDS compatibility intent uses `px4_msgs v1.16.2` and Agent `v2.4.2`.
- Third-party repositories use the exact tag at the audited HEAD where one exists.
- When the audited third-party HEAD has no exact stable tag, the script uses the current commit SHA instead of following a moving Foxy branch.
- Self-developed repositories retain `main` where that current branch is still advertised. `offboard_cpp` and `px4_bringup` use their verified current SHA because their remote `master` branch no longer exists.
- `workspace.lock.repos` pins every managed repository to a commit SHA, including annotated-tag dereferencing for `px4_msgs`.

Repositories especially important to lock by commit are moving self-developed branches (`offboard_cpp`, `px4_bringup`, `serial_driver_ros2`, `ros2_foxy_vision_to_mavros`) and untagged third-party snapshots (`gazebo_ros_pkgs`, `navigation2`, `rplidar_ros`, `serial-ros2`, `slam_toolbox`). For byte-identical committed bases, use the lock file for all repositories.

## 4. Modified files

| File | Change |
|---|---|
| `Scripts/installation/uav_px4_dds_install.sh` | Central 20-repository array, SHA-capable checkout, explicit dry-run plan, retained update/skip behavior, `colcon list` package verification |
| `docs/src_dependency_inventory.md` | 19 Git repositories, 2 local packages, dirty/detached state, and 79 manifest dependency records |
| `workspace.repos` | Human-maintained branch/tag/SHA intent for 20 repositories |
| `workspace.lock.repos` | Exact commit locks for the same 20 repositories |
| `docs/uav_install_script_update.md` | This update and verification report |

No file under `src/` was changed, and no child repository remote was modified.

## 5. Test results

| Test | Result |
|---|---|
| `bash -n Scripts/installation/uav_px4_dds_install.sh` | PASS |
| `bash Scripts/installation/uav_px4_dds_install.sh --dry-run` | PASS; 20 plans, 2 missing repositories reported as planned clones, 18 managed existing repositories skipped |
| Empty-target `--dry-run --src-dir /tmp/...` | PASS; 20 planned clones, no directory created |
| `--dry-run --update` | PASS; 18 planned updates and 2 planned clones; no Git mutation |
| Duplicate target check | PASS; 0 duplicate paths |
| `shellcheck Scripts/installation/uav_px4_dds_install.sh` | PASS; no findings |
| YAML parse | PASS; 20 repositories in each manifest |
| `git diff --check` | PASS |

Public GitHub branch/tag refs were checked with `git ls-remote` without cloning; the two removed-branch self-developed SHAs were checked with `git fetch --dry-run`. `vcs validate` additionally exposed the dead `offboard_py` URL and was not used as the YAML verdict because the installed vcstool raises an internal `UnboundLocalError` for several raw-SHA versions. No build or real download was performed.

## 6. Remaining gaps and one-device deployment status

The updated script can reconstruct the managed, committed repository base, but it cannot yet reproduce this working directory byte-for-byte or provide unattended deployment on an arbitrary new device.

Blocking gaps:

1. `offboard_py` must be republished or assigned a valid accessible remote.
2. `cv_yolo_paddle_pkg` and `opencv_cpp` need repositories (or must be moved into a tracked parent repository) before automation can restore them.
3. Nine repositories contain local changes. Locking the HEAD SHA does not preserve uncommitted edits, deleted packages, untracked source files, or file-mode changes.
4. The script restores source repositories only. OS packages, ROS 2 Foxy installation, `rosdep` resolution, udev rules, firmware, and hardware configuration remain separate deployment steps.
5. PX4-Autopilot firmware source is not present under the audited `src/` and therefore was not invented as an install entry.
6. The current root remote is `https://github.com/wanone111/BoomBoomFly.git`, which differs from the supplied target `https://github.com/BoomBoomFly/BoomBoomFly.git`; no remote was changed.

## 7. Future maintenance

1. Before changing any ref, run the inventory checks and review repository dirty/detached state.
2. Update `workspace.repos` only after selecting an intentional compatible branch/tag/SHA; never substitute a moving latest release.
3. Regenerate or update `workspace.lock.repos` from resolved commit SHAs after every approved version change.
4. Keep the script array, `workspace.repos`, and `workspace.lock.repos` target sets identical.
5. Validate with `bash -n`, `shellcheck`, default dry-run, empty-target dry-run, duplicate-target checks, YAML parsing, and public ref checks.
6. After publishing the three untracked/local source sets, add them to all three repository manifests and extend the key-package verification list if appropriate.
7. Perform the first real clone/build only on a disposable or new workspace, then run `rosdep check`, `colcon list`, and a full `colcon build` before flight hardware testing.
