# Source dependency inventory

- Audit date: 2026-07-21
- Workspace: `/home/c/BoomBoomFly`
- Scope: `src/`
- Result: 79 `package.xml` files, 19 Git repositories, and 2 local-only package directories.

## Classification

- **A — PX4 official/core DDS:** PX4 message definitions and the PX4-compatible DDS Agent.
- **B — BoomBoomFly/self-developed:** flight control, bringup, serial, and project vision packages.
- **C — third party:** ROS, navigation, SLAM, simulation, camera, lidar, MAVLink, and utility repositories.

Neither `px4_msgs` nor `Micro-XRCE-DDS-Agent` currently exists under `src/`; they are retained as managed install dependencies for the requested PX4 1.16.2/Foxy DDS deployment. There is no PX4-Autopilot firmware repository in this workspace.

## Current source repositories and local packages

| Package | Repository | URL | Branch | Commit | Type | Dirty | Detached |
|---|---|---|---|---|---|---|---|
| `gazebo_dev`, `gazebo_msgs`, `gazebo_plugins`, `gazebo_ros`, `gazebo_ros_pkgs` | `src/gazebo_ros_pkgs` | https://github.com/ros-simulation/gazebo_ros_pkgs | `foxy` | `b6f7bf121d0c607825b65a28b227a5459a71821b` | C | no | no |
| `imu_complementary_filter`, `imu_filter_madgwick`, `imu_tools`, `rviz_imu_plugin` | `src/imu_tools` | https://github.com/ccny-ros-pkg/imu_tools.git | `foxy` | `d28555e487e4c1278c9a2e94143dc79dcc8941bf` | C | no | no |
| `librealsense2` | `src/librealsense` | https://github.com/IntelRealSense/librealsense.git | — | `c94410a420b74e5fb6a414bd12215c05ddd82b69` | C | yes | yes |
| `mavlink` | `src/mavlink` | https://github.com/mavlink/mavlink-gbp-release.git | — | `22b62f8d55feb72f306d4c0147467beee490030d` | C | yes | yes |
| `libmavconn`, `mavros`, `mavros_extras`, `mavros_msgs`, `test_mavros` | `src/mavros` | git@github.com:mavlink/mavros.git | — | `48b53ccdf95f10b2ab3366c6e061fad2a76bd6c8` | C | yes | yes |
| `navigation2` and Nav2 packages | `src/navigation2` | https://github.com/ros-navigation/navigation2.git | `foxy-devel` | `ca482808a7a7c52ce01ae3c662dc2b980968fc16` | C | no | no |
| `move_base_msgs` | `src/navigation_msgs` | https://github.com/ros-planning/navigation_msgs.git | `foxy` | `fe880e99d993e9d4dfbf37f00d839d32994610e1` | C | yes | no |
| `offboard_cpp` | `src/offboard_cpp` | git@hly:AyasOwen/offboard_cpp.git (upstream: git@hly:BoomBoomFly/px4_offboard_cpp.git) | `master` | `77a02dc09212cdaa1d8ee654f0ae42ae0f04e275` | B | yes | no |
| `offboard_py` | `src/offboard_py` | git@hly:BoomBoomFly/px4_offboard_py.git | `master` | `38887f08dd91719d3efa5d969d9cb7eceff7463d` | B | no | no |
| `px4_bringup` | `src/px4_bringup` | git@hly:AyasOwen/px4_bringup.git | `master` | `0fbdcbf6ee53d6927de75af1d98f22cf5bd4f917` | B | no | no |
| `realsense2_camera`, `realsense2_camera_msgs`, `realsense2_description` | `src/realsense-ros` | https://github.com/IntelRealSense/realsense-ros.git | — | `8abb4657c0add15f87b0edbfb67eaba2c1c2c439` | C | yes | yes |
| `vision_to_mavros` | `src/ros2_foxy_vision_to_mavros` | git@github.com:AyasOwen/ros2_foxy_vision_to_mavros.git | `main` | `3d395fdc0d034758f8846f8a4cb6dc7e22185d63` | B | yes | no |
| `rplidar_ros` | `src/rplidar_ros` | https://github.com/Slamtec/rplidar_ros.git | `ros2` | `24cc9b6dea97e045bda1408eaa867ce730fd3fc3` | C | no | no |
| `rtabmap` | `src/rtabmap` | https://github.com/introlab/rtabmap.git | `foxy-devel` | `0070de4aafab0feaf5e37b497b1354d2264d41c8` | C | no | no |
| RTAB-Map ROS packages | `src/rtabmap_ros` | https://github.com/introlab/rtabmap_ros.git | `foxy-devel` | `b341e2a776a743b8d6741b8aae8ab560471cd966` | C | no | no |
| `serial` | `src/serial-ros2` | https://github.com/RoverRobotics-forks/serial-ros2.git | `master` | `ae46504ae7d4a199ea9bba0e73a6f083bf172f80` | C | no | no |
| `serial_driver` | `src/serial_driver_ros2` | https://github.com/BoomBoomFly/serial_driver_ros2.git | `main` | `8614989c8b9e60176a83d5d32a058801fafdb8d6` | B | yes | no |
| `karto_sdk`, `slam_toolbox` | `src/slam_toolbox` | https://github.com/SteveMacenski/slam_toolbox.git | `foxy-devel` | `4786e90c06a4dc6fa811c5057d4e88387fba3829` | C | no | no |
| `cv_bridge`, `opencv_tests`, `vision_opencv` | `src/vision_opencv` | https://github.com/ros-perception/vision_opencv.git | `foxy` | `72152d9d1d8edcfcafd707a1d0103810db8613ba` | C | yes | no |
| `cv_yolo_paddle_pkg` | `src/cv_yolo_paddle_pkg` | — (no Git metadata/source URL) | — | — | B (local) | n/a | n/a |
| `opencv_cpp` | `src/opencv_cpp` | — (no Git metadata/source URL) | — | — | B (local) | n/a | n/a |

Notes:

- Four repositories are detached: `librealsense`, `mavlink`, `mavros`, and `realsense-ros`.
- Nine repositories are dirty. A commit lock reproduces their committed base only, not local modifications, deletions, untracked files, or permission-mode changes.
- `src/navigation_msgs/map_msgs` and `src/vision_opencv/image_geometry` are deleted from dirty working trees, so clean clones contain additional packages relative to this exact directory.
- `cv_yolo_paddle_pkg` and `opencv_cpp` have no `.git` metadata or declared repository URL and therefore cannot be safely added to an automated clone list.
- `offboard_py` is intentionally excluded from the automated manifests: its recorded remote `git@hly:BoomBoomFly/px4_offboard_py.git` now returns `Repository not found`. The local commit must be republished before it can be restored on a new device.
- The `offboard_cpp` and `px4_bringup` remotes using SSH host alias `hly` were normalized to standard GitHub HTTPS paths. Their local branch is `master`, but the remote no longer advertises `master`; both audited current SHAs were verified with `git fetch --dry-run` and are pinned instead.

## Additional managed PX4/DDS repositories

| Package | Repository | URL | Version | Lock commit | Type | Source |
|---|---|---|---|---|---|---|
| `px4_msgs` | `src/px4_msgs` | https://github.com/PX4/px4_msgs.git | `v1.16.2` | `392e831c1f659429ca83902e66820d7094591410` | A | PX4 1.16.2 release tag |
| Micro XRCE-DDS Agent | `src/Micro-XRCE-DDS-Agent` | https://github.com/eProsima/Micro-XRCE-DDS-Agent.git | `v2.4.2` | `57d086216d01ec43121845d385894a25987f8a2c` | A | ROS 2 Foxy/Fast DDS 2.0.x compatibility |

## ROS package manifest inventory

The dependency columns contain only the requested `depend`, `exec_depend`, and `build_depend` tags. Build-tool, test, group, and other dependency tag types are intentionally outside this table.

| Package | Manifest | Version | Maintainer | depend | exec_depend | build_depend |
|---|---|---|---|---|---|---|
| `cv_yolo_paddle_pkg` | `src/cv_yolo_paddle_pkg/package.xml` | `0.0.1` | c | `rclpy,sensor_msgs,std_msgs,cv_bridge` | `—` | `—` |
| `gazebo_dev` | `src/gazebo_ros_pkgs/gazebo_dev/package.xml` | `3.5.3` | Jose Luis Rivero | `—` | `gazebo11` | `—` |
| `gazebo_msgs` | `src/gazebo_ros_pkgs/gazebo_msgs/package.xml` | `3.5.3` | Jose Luis Rivero | `—` | `rosidl_default_runtime,builtin_interfaces,geometry_msgs,trajectory_msgs,std_msgs` | `builtin_interfaces,geometry_msgs,trajectory_msgs,std_msgs` |
| `gazebo_plugins` | `src/gazebo_ros_pkgs/gazebo_plugins/package.xml` | `3.5.3` | Jose Luis Rivero | `camera_info_manager,cv_bridge,geometry_msgs,image_transport,nav_msgs,sensor_msgs,std_msgs,std_srvs,tf2_geometry_msgs,tf2_ros,trajectory_msgs` | `gazebo_dev,gazebo_msgs,gazebo_ros,rclcpp` | `gazebo_dev,gazebo_msgs,gazebo_ros,rclcpp` |
| `gazebo_ros` | `src/gazebo_ros_pkgs/gazebo_ros/package.xml` | `3.5.3` | Jose Luis Rivero | `builtin_interfaces,gazebo_dev,gazebo_msgs,rcl,rclcpp,rclpy,rmw,std_srvs,tinyxml_vendor` | `ament_index_python,geometry_msgs,launch_ros,python3-catkin-pkg,ros2pkg,std_msgs` | `—` |
| `gazebo_ros_pkgs` | `src/gazebo_ros_pkgs/gazebo_ros_pkgs/package.xml` | `3.5.3` | Jose Luis Rivero | `—` | `gazebo_dev,gazebo_msgs,gazebo_plugins,gazebo_ros` | `—` |
| `imu_complementary_filter` | `src/imu_tools/imu_complementary_filter/package.xml` | `2.0.3` | Martin Günther | `—` | `—` | `geometry_msgs,message_filters,rclcpp,sensor_msgs,std_msgs,tf2,tf2_ros` |
| `imu_filter_madgwick` | `src/imu_tools/imu_filter_madgwick/package.xml` | `2.0.3` | Martin Günther | `rclcpp,rclcpp_action,rclcpp_lifecycle,visualization_msgs,nav_msgs,geometry_msgs,builtin_interfaces,tf2_ros,tf2_geometry_msgs,sensor_msgs` | `—` | `—` |
| `imu_tools` | `src/imu_tools/imu_tools/package.xml` | `2.0.3` | Martin Günther | `—` | `imu_complementary_filter,imu_filter_madgwick,rviz_imu_plugin` | `—` |
| `rviz_imu_plugin` | `src/imu_tools/rviz_imu_plugin/package.xml` | `2.0.3` | Martin Günther | `message_filters,pluginlib,rclcpp,rviz_common,rviz_ogre_vendor,rviz_rendering,sensor_msgs,tf2,tf2_ros` | `libqt5-core,libqt5-gui,libqt5-opengl,libqt5-widgets` | `qtbase5-dev` |
| `librealsense2` | `src/librealsense/package.xml` | `2.50.0` | Sergey Dorodnicov | `—` | `—` | `pkg-config,libusb-1.0-dev,libssl-dev,libudev-dev,dkms,udev` |
| `mavlink` | `src/mavlink/package.xml` | `2022.12.30` | Vladimir Ermakov | `—` | `catkin` | `python,python-lxml,python-future,python3-dev,python3-lxml,python3-future` |
| `libmavconn` | `src/mavros/libmavconn/package.xml` | `2.7.0` | Vladimir Ermakov | `asio,mavlink,libconsole-bridge-dev` | `—` | `python3-empy` |
| `mavros` | `src/mavros/mavros/package.xml` | `2.7.0` | Vladimir Ermakov | `diagnostic_updater,message_filters,eigen_stl_containers,libmavconn,pluginlib,libconsole-bridge-dev,tf2_ros,tf2_eigen,rclcpp,rclcpp_components,rcpputils,diagnostic_msgs,geometry_msgs,mavros_msgs,nav_msgs,sensor_msgs,geographic_msgs,trajectory_msgs,std_msgs,std_srvs` | `rosidl_default_runtime,rclpy,python3-click` | `eigen,mavlink,geographiclib,geographiclib-tools,angles` |
| `mavros_extras` | `src/mavros/mavros_extras/package.xml` | `2.7.0` | Vladimir Ermakov | `diagnostic_updater,message_filters,eigen_stl_containers,mavros,libmavconn,pluginlib,tf2_ros,tf2_eigen,rclcpp,rclcpp_components,rcpputils,urdf,yaml-cpp,yaml_cpp_vendor,diagnostic_msgs,geometry_msgs,mavros_msgs,nav_msgs,sensor_msgs,geographic_msgs,trajectory_msgs,std_msgs,std_srvs,visualization_msgs` | `rosidl_default_runtime` | `eigen,mavlink,geographiclib,geographiclib-tools,angles` |
| `mavros_msgs` | `src/mavros/mavros_msgs/package.xml` | `2.7.0` | Vladimir Ermakov | `rcl_interfaces,geographic_msgs,geometry_msgs,sensor_msgs` | `rosidl_default_runtime` | `—` |
| `test_mavros` | `src/mavros/test_mavros/package.xml` | `1.18.0` | Vladimir Ermakov | `roscpp,std_msgs,geometry_msgs,tf2_ros,mavros,mavros_extras,eigen,eigen_conversions,control_toolbox` | `—` | `angles,cmake_modules` |
| `nav2_amcl` | `src/navigation2/nav2_amcl/package.xml` | `0.4.7` | Mohammad Haghighipanah | `rclcpp,tf2_geometry_msgs,geometry_msgs,message_filters,nav_msgs,sensor_msgs,std_srvs,tf2_ros,tf2,nav2_util,nav2_msgs,launch_ros,launch_testing` | `—` | `nav2_common` |
| `nav2_behavior_tree` | `src/navigation2/nav2_behavior_tree/package.xml` | `0.4.7` | Michael Jeronimo | `—` | `rclcpp,rclcpp_action,rclcpp_lifecycle,std_msgs,behaviortree_cpp_v3,builtin_interfaces,geometry_msgs,sensor_msgs,nav2_msgs,nav_msgs,tf2,tf2_ros,tf2_geometry_msgs,nav2_util,lifecycle_msgs` | `rclcpp,rclcpp_action,rclcpp_lifecycle,behaviortree_cpp_v3,builtin_interfaces,geometry_msgs,sensor_msgs,nav2_msgs,nav_msgs,tf2,tf2_ros,tf2_geometry_msgs,std_msgs,std_srvs,nav2_util,lifecycle_msgs,nav2_common` |
| `nav2_bringup` | `src/navigation2/nav2_bringup/bringup/package.xml` | `0.4.7` | Michael Jeronimo | `—` | `launch_ros,navigation2,nav2_common,slam_toolbox` | `nav2_common,navigation2,launch_ros` |
| `nav2_gazebo_spawner` | `src/navigation2/nav2_bringup/nav2_gazebo_spawner/package.xml` | `0.4.7` | lkumarbe | `—` | `rclpy,std_msgs` | `—` |
| `nav2_bt_navigator` | `src/navigation2/nav2_bt_navigator/package.xml` | `0.4.7` | Michael Jeronimo | `tf2_ros` | `behaviortree_cpp_v3,rclcpp,rclcpp_action,rclcpp_lifecycle,nav2_behavior_tree,nav_msgs,nav2_msgs,std_msgs,nav2_util,geometry_msgs` | `nav2_common,rclcpp,rclcpp_action,rclcpp_lifecycle,nav2_behavior_tree,nav_msgs,nav2_msgs,behaviortree_cpp_v3,std_msgs,geometry_msgs,std_srvs,nav2_util` |
| `nav2_common` | `src/navigation2/nav2_common/package.xml` | `0.4.7` | Carl Delsey | `launch,launch_ros,osrf_pycommon,rclpy,python3-yaml` | `—` | `ament_cmake_python` |
| `nav2_controller` | `src/navigation2/nav2_controller/package.xml` | `0.4.7` | Carl Delsey | `angles,rclcpp,rclcpp_action,std_msgs,nav2_util,nav2_msgs,nav_2d_utils,nav_2d_msgs,nav2_core,pluginlib` | `—` | `nav2_common` |
| `nav2_core` | `src/navigation2/nav2_core/package.xml` | `0.4.7` | Steve Macenski | `rclcpp,rclcpp_lifecycle,std_msgs,geometry_msgs,nav2_costmap_2d,pluginlib,nav_msgs,tf2_ros,nav2_util` | `—` | `nav2_common` |
| `nav2_costmap_2d` | `src/navigation2/nav2_costmap_2d/package.xml` | `0.4.7` | Steve Macenski | `angles,geometry_msgs,laser_geometry,map_msgs,message_filters,nav2_msgs,nav2_util,nav2_voxel_grid,nav_msgs,pluginlib,rclcpp,rclcpp_lifecycle,sensor_msgs,std_msgs,tf2,tf2_geometry_msgs,tf2_ros,tf2_sensor_msgs,visualization_msgs` | `—` | `nav2_common` |
| `costmap_queue` | `src/navigation2/nav2_dwb_controller/costmap_queue/package.xml` | `0.4.7` | David V. Lu!! | `nav2_costmap_2d,rclcpp` | `—` | `nav2_common` |
| `dwb_core` | `src/navigation2/nav2_dwb_controller/dwb_core/package.xml` | `0.4.7` | Carl Delsey | `—` | `rclcpp,std_msgs,rclcpp,std_msgs,geometry_msgs,dwb_msgs,nav2_costmap_2d,nav_2d_utils,pluginlib,nav_msgs,tf2_ros,nav2_util,nav2_core` | `nav2_common,rclcpp,std_msgs,geometry_msgs,nav_2d_msgs,dwb_msgs,nav2_costmap_2d,pluginlib,sensor_msgs,visualization_msgs,nav_2d_utils,nav_msgs,tf2_ros,nav2_util,nav2_core` |
| `dwb_critics` | `src/navigation2/nav2_dwb_controller/dwb_critics/package.xml` | `0.4.7` | David V. Lu!! | `angles,nav2_costmap_2d,nav2_util,costmap_queue,dwb_core,geometry_msgs,nav_2d_msgs,nav_2d_utils,pluginlib,rclcpp,sensor_msgs` | `—` | `nav2_common` |
| `dwb_msgs` | `src/navigation2/nav2_dwb_controller/dwb_msgs/package.xml` | `0.4.7` | David V. Lu!! | `builtin_interfaces,geometry_msgs,nav_2d_msgs,std_msgs,nav_msgs,rosidl_default_runtime` | `—` | `—` |
| `dwb_plugins` | `src/navigation2/nav2_dwb_controller/dwb_plugins/package.xml` | `0.4.7` | David V. Lu!! | `angles,dwb_core,nav_2d_msgs,nav_2d_utils,pluginlib,rclcpp,nav2_util` | `—` | `nav2_common` |
| `nav2_dwb_controller` | `src/navigation2/nav2_dwb_controller/nav2_dwb_controller/package.xml` | `0.4.7` | Carl Delsey | `costmap_queue,dwb_core,dwb_critics,dwb_msgs,dwb_plugins,nav_2d_msgs,nav_2d_utils` | `—` | `—` |
| `nav_2d_msgs` | `src/navigation2/nav2_dwb_controller/nav_2d_msgs/package.xml` | `0.4.7` | David V. Lu!! | `geometry_msgs,std_msgs,rosidl_default_generators` | `—` | `—` |
| `nav_2d_utils` | `src/navigation2/nav2_dwb_controller/nav_2d_utils/package.xml` | `0.4.7` | David V. Lu!! | `geometry_msgs,nav_2d_msgs,nav_msgs,tf2,tf2_geometry_msgs,nav2_msgs,nav2_util` | `—` | `nav2_common` |
| `nav2_lifecycle_manager` | `src/navigation2/nav2_lifecycle_manager/package.xml` | `0.4.7` | Michael Jeronimo | `—` | `geometry_msgs,lifecycle_msgs,nav2_msgs,nav2_util,rclcpp_action,rclcpp_lifecycle,std_msgs,std_srvs,tf2_geometry_msgs` | `geometry_msgs,lifecycle_msgs,nav2_msgs,nav2_util,rclcpp_action,rclcpp_lifecycle,std_msgs,std_srvs,tf2_geometry_msgs,nav2_common` |
| `nav2_map_server` | `src/navigation2/nav2_map_server/package.xml` | `0.4.7` | Brian Wilcox | `rclcpp_lifecycle,nav_msgs,std_msgs,rclcpp,yaml_cpp_vendor,launch_ros,launch_testing,tf2,nav2_msgs,nav2_util,graphicsmagick` | `—` | `nav2_common` |
| `nav2_msgs` | `src/navigation2/nav2_msgs/package.xml` | `0.4.7` | Michael Jeronimo | `rclcpp,std_msgs,builtin_interfaces,rosidl_default_generators,geometry_msgs,action_msgs,nav_msgs` | `—` | `nav2_common` |
| `nav2_navfn_planner` | `src/navigation2/nav2_navfn_planner/package.xml` | `0.4.7` | Steve Macenski | `rclcpp,rclcpp_action,rclcpp_lifecycle,visualization_msgs,nav2_util,nav2_msgs,nav_msgs,geometry_msgs,builtin_interfaces,nav2_common,tf2_ros,nav2_costmap_2d,nav2_core,pluginlib` | `—` | `—` |
| `nav2_planner` | `src/navigation2/nav2_planner/package.xml` | `0.4.7` | Steve Macenski | `rclcpp,rclcpp_action,rclcpp_lifecycle,visualization_msgs,nav2_util,nav2_msgs,nav_msgs,geometry_msgs,builtin_interfaces,nav2_common,tf2_ros,nav2_costmap_2d,pluginlib,nav2_core` | `—` | `—` |
| `nav2_recoveries` | `src/navigation2/nav2_recoveries/package.xml` | `0.4.7` | Carlos Orduno | `—` | `rclcpp,rclcpp_action,rclcpp_lifecycle,nav2_behavior_tree,nav2_util,nav2_msgs,nav_msgs,geometry_msgs,nav2_costmap_2d,nav2_core,pluginlib` | `nav2_common,rclcpp,rclcpp_action,rclcpp_lifecycle,nav2_behavior_tree,nav2_util,nav2_msgs,nav_msgs,tf2,tf2_geometry_msgs,geometry_msgs,nav2_costmap_2d,nav2_core,pluginlib` |
| `nav2_regulated_pure_pursuit_controller` | `src/navigation2/nav2_regulated_pure_pursuit_controller/package.xml` | `0.4.7` | Steve Macenski | `nav2_common,nav2_core,nav2_util,nav2_costmap_2d,rclcpp,geometry_msgs,nav2_msgs,pluginlib,tf2` | `—` | `—` |
| `nav2_rviz_plugins` | `src/navigation2/nav2_rviz_plugins/package.xml` | `0.4.7` | Michael Jeronimo | `geometry_msgs,nav2_util,nav2_lifecycle_manager,nav2_msgs,nav_msgs,pluginlib,rclcpp,rclcpp_lifecycle,resource_retriever,rviz_common,rviz_default_plugins,rviz_ogre_vendor,rviz_rendering,std_msgs,tf2_geometry_msgs,visualization_msgs` | `libqt5-core,libqt5-gui,libqt5-opengl,libqt5-widgets` | `qtbase5-dev` |
| `nav2_system_tests` | `src/navigation2/nav2_system_tests/package.xml` | `0.4.7` | Carlos Orduno | `—` | `launch_ros,launch_testing,rclcpp,rclpy,nav2_bringup,nav2_util,nav2_map_server,nav2_msgs,nav2_lifecycle_manager,nav2_navfn_planner,nav_msgs,visualization_msgs,geometry_msgs,nav2_amcl,std_msgs,tf2_geometry_msgs,gazebo_ros_pkgs,navigation2,lcov,robot_state_publisher,nav2_planner` | `nav2_common,rclcpp,rclpy,nav2_util,nav2_map_server,nav2_msgs,nav2_lifecycle_manager,nav2_navfn_planner,nav_msgs,visualization_msgs,nav2_amcl,launch_ros,launch_testing,geometry_msgs,std_msgs,tf2_geometry_msgs,gazebo_ros_pkgs,launch_ros,launch_testing,nav2_planner` |
| `nav2_util` | `src/navigation2/nav2_util/package.xml` | `0.4.7` | Michael Jeronimo | `nav2_common,geometry_msgs,rclcpp,nav2_msgs,nav_msgs,tf2,tf2_ros,tf2_geometry_msgs,lifecycle_msgs,rclcpp_action,test_msgs,rclcpp_lifecycle,launch,launch_testing_ament_cmake,action_msgs` | `libboost-program-options` | `libboost-program-options-dev` |
| `nav2_voxel_grid` | `src/navigation2/nav2_voxel_grid/package.xml` | `0.4.7` | Carl Delsey | `rclcpp` | `—` | `nav2_common` |
| `nav2_waypoint_follower` | `src/navigation2/nav2_waypoint_follower/package.xml` | `0.4.7` | Steve Macenski | `nav2_common,rclcpp,rclcpp_action,rclcpp_lifecycle,nav_msgs,nav2_msgs,nav2_util,tf2_ros` | `—` | `—` |
| `navigation2` | `src/navigation2/navigation2/package.xml` | `0.4.7` | Steve Macenski | `—` | `nav2_amcl,nav2_bt_navigator,nav2_costmap_2d,nav2_core,nav2_dwb_controller,nav2_lifecycle_manager,nav2_map_server,nav2_recoveries,nav2_planner,nav2_msgs,nav2_navfn_planner,nav2_rviz_plugins,nav2_behavior_tree,nav2_util,nav2_voxel_grid,nav2_controller,nav2_waypoint_follower,smac_planner,nav2_regulated_pure_pursuit_controller` | `—` |
| `smac_planner` | `src/navigation2/smac_planner/package.xml` | `0.4.7` | Steve Macenski | `rclcpp,rclcpp_action,rclcpp_lifecycle,visualization_msgs,nav2_util,nav2_msgs,nav_msgs,geometry_msgs,builtin_interfaces,nav2_common,tf2_ros,nav2_costmap_2d,nav2_core,pluginlib,libceres-dev,eigen3_cmake_module,eigen,ompl` | `—` | `—` |
| `move_base_msgs` | `src/navigation_msgs/move_base_msgs/package.xml` | `2.0.2` | Steve Macenski | `action_msgs,geometry_msgs` | `rosidl_default_runtime` | `rosidl_default_generators` |
| `offboard_cpp` | `src/offboard_cpp/package.xml` | `0.0.2` | orangepi | `action_msgs,rclcpp,std_msgs,geometry_msgs,mavros_msgs,tf2,tf2_ros,tf2_geometry_msgs,opencv` | `—` | `—` |
| `offboard_py` | `src/offboard_py/package.xml` | `0.0.1` | orangepi | `—` | `rclpy,geometry_msgs,mavros_msgs` | `—` |
| `opencv_cpp` | `src/opencv_cpp/package.xml` | `0.0.0` | c | `rclcpp,std_msgs,geometry_msgs,sensor_msgs` | `—` | `—` |
| `px4_bringup` | `src/px4_bringup/package.xml` | `0.0.1` | c | `—` | `launch,launch_ros,rclpy` | `—` |
| `realsense2_camera` | `src/realsense-ros/realsense2_camera/package.xml` | `4.0.4` | LibRealSense ROS Team | `eigen,builtin_interfaces,cv_bridge,image_transport,librealsense2,rclcpp,rclcpp_components,realsense2_camera_msgs,sensor_msgs,geometry_msgs,std_msgs,nav_msgs,tf2,tf2_ros,diagnostic_updater` | `launch_ros` | `ros_environment` |
| `realsense2_camera_msgs` | `src/realsense-ros/realsense2_camera_msgs/package.xml` | `4.0.4` | LibRealSense ROS Team | `—` | `rosidl_default_runtime,builtin_interfaces,std_msgs` | `builtin_interfaces,std_msgs` |
| `realsense2_description` | `src/realsense-ros/realsense2_description/package.xml` | `4.0.4` | LibRealSense ROS Team | `rclcpp,rclcpp_components,realsense2_camera_msgs` | `launch_ros,xacro` | `—` |
| `vision_to_mavros` | `src/ros2_foxy_vision_to_mavros/package.xml` | `0.0.0` | samuel | `—` | `mavros_msgs,geometry_msgs,cv_bridge,std_msgs,rclcpp,tf2,tf2_ros,tf2_msgs,ros2launch` | `geometry_msgs,cv_bridge,std_msgs,rclcpp,tf2,tf2_ros,tf2_msgs,mavros_msgs` |
| `rplidar_ros` | `src/rplidar_ros/package.xml` | `2.1.4` | Wang DeYou | `—` | `rclcpp,sensor_msgs,std_srvs,rclcpp_components` | `rclcpp,sensor_msgs,std_srvs,rclcpp_components` |
| `rtabmap` | `src/rtabmap/package.xml` | `0.21.1` | Mathieu Labbe | `cv_bridge,libfreenect-dev,libg2o,libopenni-dev,libpcl-all-dev,libpointmatcher,libsqlite3-dev,octomap,qt_gui_cpp,zlib` | `—` | `proj` |
| `rtabmap_conversions` | `src/rtabmap_ros/rtabmap_conversions/package.xml` | `0.21.1` | Mathieu Labbe | `cv_bridge,geometry_msgs,image_geometry,laser_geometry,pcl_conversions,rclcpp,rclcpp_components,rtabmap,rtabmap_msgs,sensor_msgs,std_msgs,tf2,tf2_eigen,tf2_geometry_msgs` | `—` | `ros_environment` |
| `rtabmap_demos` | `src/rtabmap_ros/rtabmap_demos/package.xml` | `0.21.1` | Mathieu Labbe | `—` | `rtabmap_odom,rtabmap_slam,rtabmap_util,rtabmap_rviz_plugins,rtabmap_viz,turtlebot3,nav2_bringup` | `—` |
| `rtabmap_examples` | `src/rtabmap_ros/rtabmap_examples/package.xml` | `0.21.1` | Mathieu Labbe | `—` | `rtabmap_odom,rtabmap_slam,rtabmap_util,rtabmap_rviz_plugins,rtabmap_slam,rtabmap_util,rtabmap_viz,imu_filter_madgwick,tf2_ros,realsense2_camera,velodyne` | `—` |
| `rtabmap_launch` | `src/rtabmap_ros/rtabmap_launch/package.xml` | `0.21.1` | Mathieu Labbe | `—` | `rtabmap_odom,rtabmap_slam,rtabmap_msgs,rtabmap_util,rtabmap_rviz_plugins,rtabmap_slam,rtabmap_util,rtabmap_viz` | `—` |
| `rtabmap_msgs` | `src/rtabmap_ros/rtabmap_msgs/package.xml` | `0.21.1` | Mathieu Labbe | `std_msgs,std_srvs,geometry_msgs,sensor_msgs` | `rosidl_default_runtime` | `rosidl_default_generators` |
| `rtabmap_odom` | `src/rtabmap_ros/rtabmap_odom/package.xml` | `0.21.1` | Mathieu Labbe | `cv_bridge,image_geometry,laser_geometry,message_filters,nav_msgs,pcl_conversions,pcl_ros,pluginlib,rclcpp,rclcpp_components,sensor_msgs,rtabmap_conversions,rtabmap_msgs,rtabmap_util` | `—` | `—` |
| `rtabmap_python` | `src/rtabmap_ros/rtabmap_python/package.xml` | `0.21.1` | Mathieu Labbe | `—` | `—` | `—` |
| `rtabmap_ros` | `src/rtabmap_ros/rtabmap_ros/package.xml` | `0.21.1` | Mathieu Labbe | `—` | `rtabmap_conversions,rtabmap_demos,rtabmap_examples,rtabmap_launch,rtabmap_msgs,rtabmap_odom,rtabmap_python,rtabmap_rviz_plugins,rtabmap_slam,rtabmap_sync,rtabmap_util,rtabmap_viz` | `—` |
| `rtabmap_rviz_plugins` | `src/rtabmap_ros/rtabmap_rviz_plugins/package.xml` | `0.21.1` | Mathieu Labbe | `pcl_conversions,pluginlib,rclcpp,rviz_common,rviz_rendering,rviz_default_plugins,sensor_msgs,std_msgs,tf2,rtabmap_conversions,rtabmap_msgs` | `—` | `—` |
| `rtabmap_slam` | `src/rtabmap_ros/rtabmap_slam/package.xml` | `0.21.1` | Mathieu Labbe | `cv_bridge,geometry_msgs,nav_msgs,nav2_msgs,rclcpp,rclcpp_components,sensor_msgs,std_msgs,std_srvs,tf2,tf2_ros,visualization_msgs,rtabmap_msgs,rtabmap_util,rtabmap_sync` | `—` | `—` |
| `rtabmap_sync` | `src/rtabmap_ros/rtabmap_sync/package.xml` | `0.21.1` | Mathieu Labbe | `cv_bridge,image_transport,message_filters,nav_msgs,rclcpp,rclcpp_components,rtabmap_conversions,rtabmap_msgs,sensor_msgs` | `—` | `—` |
| `rtabmap_util` | `src/rtabmap_ros/rtabmap_util/package.xml` | `0.21.1` | Mathieu Labbe | `cv_bridge,image_transport,rclcpp,rclcpp_components,octomap_msgs,sensor_msgs,stereo_msgs,nav_msgs,std_msgs,tf2,tf2_ros,laser_geometry,pcl_conversions,pcl_ros,message_filters,rtabmap_msgs,rtabmap_conversions` | `—` | `—` |
| `rtabmap_viz` | `src/rtabmap_ros/rtabmap_viz/package.xml` | `0.21.1` | Mathieu Labbe | `cv_bridge,geometry_msgs,rclcpp,std_msgs,std_srvs,nav_msgs,rtabmap_msgs,rtabmap_sync,tf2` | `—` | `—` |
| `serial` | `src/serial-ros2/package.xml` | `1.2.1` | William Woodall | `—` | `—` | `—` |
| `serial_driver` | `src/serial_driver_ros2/package.xml` | `0.1.0` | Your Name | `rclcpp,geometry_msgs` | `—` | `—` |
| `karto_sdk` | `src/slam_toolbox/lib/karto_sdk/package.xml` | `1.1.4` | Michael Ferguson | `—` | `—` | `boost,tbb,libblas-dev,liblapack-dev` |
| `slam_toolbox` | `src/slam_toolbox/package.xml` | `2.4.1` | Steve Macenski | `rviz_common,rviz_default_plugins,rviz_ogre_vendor,rviz_rendering` | `eigen,pluginlib,message_filters,nav_msgs,rclcpp,sensor_msgs,tf2,tf2_ros,tf2_sensor_msgs,visualization_msgs,std_srvs,boost,interactive_markers,std_msgs,suitesparse,liblapack-dev,libceres-dev,tf2_geometry_msgs,tbb,libqt5-core,libqt5-widgets,nav2_common,nav2_map_server,builtin_interfaces,rosidl_default_generators,libqt5-core,libqt5-gui,libqt5-opengl,libqt5-widgets` | `pluginlib,eigen,message_filters,nav_msgs,rclcpp,sensor_msgs,tf2_ros,tf2,tf2_sensor_msgs,visualization_msgs,std_srvs,boost,interactive_markers,std_msgs,suitesparse,liblapack-dev,libceres-dev,tf2_geometry_msgs,tbb,libqt5-core,libqt5-widgets,qtbase5-dev,nav2_map_server,builtin_interfaces,rosidl_default_generators` |
| `cv_bridge` | `src/vision_opencv/cv_bridge/package.xml` | `3.0.7` | Kenji Brameld | `libopencv-dev,python3-numpy,rcpputils,sensor_msgs,python3-opencv` | `ament_index_python,libboost-python` | `libboost-dev,libboost-python-dev` |
| `opencv_tests` | `src/vision_opencv/opencv_tests/package.xml` | `3.0.7` | Kenji Brameld | `—` | `launch,rclpy,sensor_msgs,cv_bridge` | `rclpy` |
| `vision_opencv` | `src/vision_opencv/vision_opencv/package.xml` | `3.0.7` | Kenji Brameld | `—` | `cv_bridge,image_geometry` | `—` |
