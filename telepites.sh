!/bin/bash

echo "First arg: $1"
if [ "$1" != "wifi" ]
then
    echo "++++ default install settings ++++"
else
    echo "!!!! wifi settings !!!!"
    sleep 2
fi

echo "++++ install script start ++++"
echo ""

# ================================
# 1. Locale check (UTF-8)
# ================================
echo "==== Checking locale ===="
if ! locale | grep -q "en_US.UTF-8"; then
    echo "Setting up en_US.UTF-8 locale..."
    sudo apt update && sudo apt install locales -y
    sudo locale-gen en_US en_US.UTF-8
    sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
    export LANG=en_US.UTF-8
else
    echo "✔ en_US.UTF-8 locale already set."
fi

# ================================
# 2. ROS 2 Jazzy installation
# ================================
echo "==== Installing ROS 2 Jazzy ===="

# Check if ROS 2 is already installed
if ! dpkg -l | grep -q "ros-jazzy-desktop"; then
    echo "Installing ROS 2 Jazzy..."
    sudo apt install software-properties-common -y
    sudo add-apt-repository universe -y
    sudo apt update -y && sudo apt install curl -y
    sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
    sudo apt update -y
    sudo apt install ros-jazzy-desktop -y
else
    echo "✔ ROS 2 Jazzy is already installed."
fi

# ================================
# 3. Essential tools (colcon, git, etc.)
# ================================
echo "==== Installing essential tools ===="

# Check and install colcon if missing
if ! dpkg -l | grep -q "python3-colcon-common-extensions"; then
    sudo apt install python3-colcon-common-extensions -y
else
    echo "✔ colcon is already installed."
fi

# Check and install git if missing
if ! dpkg -l | grep -q "git"; then
    sudo apt install git -y
else
    echo "✔ git is already installed."
fi

# ================================
# 4. ~/.bashrc updates (only if missing)
# ================================                                                                                                             echo "==== Updating ~/.bashrc ===="                                                                                                                                                                                                                                                             #!/bin/bash                                                                                                                                     USER_HOME=$(eval echo ~${SUDO_USER:-$USER})                                                                                                     BASHRC="$USER_HOME/.bashrc"                                                                                                                                                                                                                                                                                                                                                                                                                     # 🔹 Add ROS sourcing if not already present                                                                                                    if ! grep -q "source /opt/ros/jazzy/setup.bash" "$BASHRC"; then                                                                                     echo "Adding ROS sourcing to $BASHRC..."                                                                                                        {                                                                                                                                                   echo ""                                                                                                                                         echo "#### ADDED BY INSTALL SCRIPT"                                                                                                             echo "source /opt/ros/jazzy/setup.bash"                                                                                                         echo "export RCUTILS_COLORIZED_OUTPUT=1"                                                                                                    } >> "$BASHRC"                                                                                                                              else                                                                                                                                                echo "✔ ROS sourcing already present."                                                                                                      fi                                                                                                                                                                                                                                                                                              # 🔹 Add robot ID variables if not already present                                                                                              if ! grep -q "ROBOT_NUM=" "$BASHRC"; then                                                                                                           echo "Setting up robot variables..."                                                                                                            {                                                                                                                                                   echo "ROBOT_NUM=\"100\""                                                                                                                        echo "ROBOT_ID=\"wheeltec_UNDEFINED_100\""                                                                                                  } >> "$BASHRC"                                                                                                                              else                                                                                                                                                echo "✔ Robot variables already set."                                                                                                       fi
# ================================
# 5. Workspace setup (only if missing)
# ================================
echo "==== Setting up workspace ===="

if [ ! -d ~/ros2_ws/src ]; then
    echo "Creating workspace..."
    mkdir -p ~/ros2_ws/src
    cd ~/ros2_ws/src
    git clone https://github.com/robotverseny/drivers
    git clone https://github.com/robotverseny/lane_following_cam
    git clone https://github.com/robotverseny/jkk_utils
    cd ~/ros2_ws
    source ~/.bashrc
    colcon build --symlink-install --packages-select serial wheeltec_robot_msg lslidar_msgs lslidar_driver turn_on_wheeltec_robot wheeltec_robot_urdf usb_cam_launcher lane_following_cam mcap_rec
else
    echo "✔ Workspace already exists. Skipping git clone."
fi

# ================================
# 6. Additional tools (if missing)
# ================================
echo "==== Installing additional tools ===="

# Check and install foxglove-bridge
if ! dpkg -l | grep -q "ros-jazzy-foxglove-bridge"; then
    sudo apt install ros-jazzy-foxglove-bridge -y
else
    echo "✔ foxglove-bridge already installed."
fi

# Check and install MC (Midnight Commander)
if ! dpkg -l | grep -q "mc"; then
    sudo apt install mc -y
else
    echo "✔ mc already installed."
fi

# Check and install ros-ign-bridge
if ! dpkg -l | grep -q "ros-jazzy-ros-gz"; then
    sudo apt install ros-jazzy-ros-gz -y
else
    echo "✔ ros-jazzy-ros-gz already installed."
fi

# ================================
# 7. WiFi/SSH setup (if requested)
# ================================
echo "First arg: $1"
if [ "$1" != "wifi" ]
then
    echo ""
else
    echo "!!!! wifi settings !!!!"
    # Check if SSH is installed
    if ! dpkg -l | grep -q "openssh-server"; then
        sudo apt install openssh-server -y
    else
        echo "✔ openssh-server already installed."
    fi
fi

echo ""
echo "++++ install script end ++++"
echo ""
