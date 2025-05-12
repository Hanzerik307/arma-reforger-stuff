#!/usr/bin/env python3
#
# Dependencies: python3-pyqt5 jq systemd 
#
# armar-sc-gui.py - Version 1.0 - 2025-05-08
#
# Copyright (c) 2025 Hanzerik307
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import sys
import subprocess
import json
import os
import re
from PyQt5.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, QPushButton,
    QLabel, QTabWidget, QLineEdit, QComboBox, QCheckBox, QTextEdit,
    QMessageBox, QDialog, QTextBrowser, QScrollArea
)
from PyQt5.QtCore import Qt, QProcess
from PyQt5.QtGui import QPalette, QColor, QFont

class ConfigDialog(QDialog):
    def __init__(self, config_content, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Server Configuration")
        self.setGeometry(100, 100, 500, 400)
        layout = QVBoxLayout()
        text_browser = QTextBrowser()
        text_browser.setText(config_content)
        layout.addWidget(text_browser)
        close_button = QPushButton("Close")
        close_button.clicked.connect(self.accept)
        layout.addWidget(close_button)
        self.setLayout(layout)

class AddModsDialog(QDialog):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Add Multiple Mods")
        self.setGeometry(100, 100, 400, 300)
        layout = QVBoxLayout()

        # Instructions
        layout.addWidget(QLabel("Enter up to 5 Mod IDs (16 alphanumeric characters each). Empty fields are ignored:"))

        # Create 5 input fields
        self.mod_inputs = []
        for i in range(5):
            mod_input = QLineEdit()
            mod_input.setPlaceholderText(f"Mod ID {i+1} (e.g., ABCDEF1234567890)")
            self.mod_inputs.append(mod_input)
            layout.addWidget(mod_input)

        # Buttons
        button_layout = QHBoxLayout()
        self.add_button = QPushButton("Add Mods")
        self.cancel_button = QPushButton("Cancel")
        self.add_button.clicked.connect(self.accept)
        self.cancel_button.clicked.connect(self.reject)
        button_layout.addWidget(self.add_button)
        button_layout.addWidget(self.cancel_button)
        layout.addLayout(button_layout)

        self.setLayout(layout)

    def get_mod_ids(self):
        """Return a list of non-empty mod IDs from the input fields."""
        return [mod_input.text().strip().upper() for mod_input in self.mod_inputs if mod_input.text().strip()]

class ArmaServerControlApp(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Arma Reforger Server Control")
        self.setGeometry(100, 100, 600, 600)
        self.is_dark_theme = False  # Track theme state

        # Paths from bash script
        self.config_file = os.path.expanduser("~/arma/server.json")
        self.addons_dir = os.path.expanduser("~/arma/profile/addons")

        # Scenarios from bash script
        self.scenarios = [
            ("{ECC61978EDCC2B5A}Missions/23_Campaign.conf", "Conflict - Everon"),
            ("{59AD59368755F41A}Missions/21_GM_Eden.conf", "Game Master - Everon"),
            ("{2BBBE828037C6F4B}Missions/22_GM_Arland.conf", "Game Master - Arland"),
            ("{C700DB41F0C546E1}Missions/23_Campaign_NorthCentral.conf", "Conflict - Northern Everon"),
            ("{28802845ADA64D52}Missions/23_Campaign_SWCoast.conf", "Conflict - Southern Everon"),
            ("{94992A3D7CE4FF8A}Missions/23_Campaign_Western.conf", "Conflict - Western Everon"),
            ("{FDE33AFE2ED7875B}Missions/23_Campaign_Montignac.conf", "Conflict - Montignac"),
            ("{DAA03C6E6099D50F}Missions/24_CombatOps.conf", "Combat Ops - Arland"),
            ("{C41618FD18E9D714}Missions/23_Campaign_Arland.conf", "Conflict - Arland"),
            ("{DFAC5FABD11F2390}Missions/26_CombatOpsEveron.conf", "Combat Ops - Everon"),
            ("{3F2E005F43DBD2F8}Missions/CAH_Briars_Coast.conf", "Capture & Hold: Briars"),
            ("{F1A1BEA67132113E}Missions/CAH_Castle.conf", "Capture & Hold: Montfort Castle"),
            ("{589945FB9FA7B97D}Missions/CAH_Concrete_Plant.conf", "Capture & Hold: Concrete Plant"),
            ("{9405201CBD22A30C}Missions/CAH_Factory.conf", "Capture & Hold: Almara Factory"),
            ("{1CD06B409C6FAE56}Missions/CAH_Forest.conf", "Capture & Hold: Simon's Wood"),
            ("{7C491B1FCC0FF0E1}Missions/CAH_LeMoule.conf", "Capture & Hold: Le Moule"),
            ("{6EA2E454519E5869}Missions/CAH_Military_Base.conf", "Capture & Hold: Camp Blake"),
            ("{2B4183DF23E88249}Missions/CAH_Morton.conf", "Capture & Hold: Morton"),
        ]

        # Main widget and layout
        self.central_widget = QWidget()
        self.setCentralWidget(self.central_widget)
        self.layout = QVBoxLayout(self.central_widget)

        # Theme toggle button
        self.theme_button = QPushButton("Switch to Dark Theme")
        self.theme_button.clicked.connect(self.toggle_theme)
        self.layout.addWidget(self.theme_button)

        # Tabs for different functionalities
        self.tabs = QTabWidget()
        self.layout.addWidget(self.tabs)

        # Service Management Tab
        self.service_tab = QWidget()
        self.service_layout = QVBoxLayout(self.service_tab)

        # Status button at top center
        status_layout = QHBoxLayout()
        self.status_button = QPushButton("Status")
        self.status_button.setFixedSize(100, 30)
        font = QFont()
        font.setPointSize(8)
        self.status_button.setFont(font)
        self.status_button.clicked.connect(self.show_status)
        status_layout.addStretch()
        status_layout.addWidget(self.status_button)
        status_layout.addStretch()
        self.service_layout.addLayout(status_layout)

        # Log window
        self.log_window = QTextEdit()
        self.log_window.setReadOnly(True)
        self.log_window.setPlaceholderText("Service logs will appear here...")
        self.service_layout.addWidget(QLabel("Service Logs:"))
        self.service_layout.addWidget(self.log_window)

        # Start/Stop/Restart buttons at bottom
        self.start_button = QPushButton("Start Service")
        self.stop_button = QPushButton("Stop Service")
        self.restart_button = QPushButton("Restart Service")
        self.start_button.clicked.connect(self.start_service)
        self.stop_button.clicked.connect(self.stop_service)
        self.restart_button.clicked.connect(self.restart_service)

        # Set button colors
        self.start_button.setStyleSheet("background-color: #00FF00;")
        self.stop_button.setStyleSheet("background-color: #FF0000;")
        self.restart_button.setStyleSheet("background-color: #FFFF00;")
        self.update_status_button_color()

        button_layout = QHBoxLayout()
        button_layout.addWidget(self.start_button)
        button_layout.addWidget(self.stop_button)
        button_layout.addWidget(self.restart_button)
        self.service_layout.addLayout(button_layout)
        self.tabs.addTab(self.service_tab, "Service Control")

        # Initialize journalctl process for logging
        self.log_process = QProcess(self)
        self.log_process.readyReadStandardOutput.connect(self.handle_log_output)
        self.log_process.readyReadStandardError.connect(self.handle_log_output)
        self.start_logging()

        # Server Configuration Tab
        self.config_tab = QWidget()
        self.config_scroll = QScrollArea()
        self.config_scroll.setWidgetResizable(True)
        self.config_scroll.setWidget(self.config_tab)
        self.config_layout = QVBoxLayout(self.config_tab)
        self.config_layout.addWidget(QLabel("Server Configuration:"))

        # Network Settings
        self.ip_input = QLineEdit()
        self.port_input = QLineEdit()
        self.port_input.setPlaceholderText("1024-65535")
        self.config_layout.addWidget(QLabel("Public IP Address:"))
        self.config_layout.addWidget(self.ip_input)
        self.config_layout.addWidget(QLabel("Public Port (1024-65535):"))
        self.config_layout.addWidget(self.port_input)

        # Game Settings
        self.name_input = QLineEdit()
        self.game_password_input = QLineEdit()
        self.admin_password_input = QLineEdit()
        self.admins_input = QTextEdit()
        self.admins_input.setPlaceholderText("Enter up to 20 Player IdentityIds, one per line (e.g., 3690a2f4-edb0-434e-ab2e-758906631a38)")
        self.admins_input.setFixedHeight(100)
        self.scenario_combo = QComboBox()
        self.scenario_combo.addItems([desc for _, desc in self.scenarios])
        self.custom_scenario_input = QLineEdit()
        self.custom_scenario_input.setPlaceholderText("e.g., {ECC61978EDCC2B5A}Missions/23_Campaign.conf")
        self.max_players_input = QLineEdit()
        self.max_players_input.setPlaceholderText("2-128")
        self.config_layout.addWidget(QLabel("Server Name:"))
        self.config_layout.addWidget(self.name_input)
        self.config_layout.addWidget(QLabel("Game Password:"))
        self.config_layout.addWidget(self.game_password_input)
        self.config_layout.addWidget(QLabel("Admin Password:"))
        self.config_layout.addWidget(self.admin_password_input)
        self.config_layout.addWidget(QLabel("Admins (up to 20 Player IdentityIds):"))
        self.config_layout.addWidget(self.admins_input)
        self.config_layout.addWidget(QLabel("Scenario:"))
        self.config_layout.addWidget(self.scenario_combo)
        self.config_layout.addWidget(QLabel("Custom Mod Scenario ID From Workshop (Overrides dropdown if filled in):"))
        self.config_layout.addWidget(self.custom_scenario_input)
        self.config_layout.addWidget(QLabel("Max Players (2-128):"))
        self.config_layout.addWidget(self.max_players_input)

        # Game Properties
        self.view_distance_input = QLineEdit()
        self.view_distance_input.setPlaceholderText("500-10000")
        self.grass_distance_input = QLineEdit()
        self.grass_distance_input.setPlaceholderText("50-150")
        self.network_view_distance_input = QLineEdit()
        self.network_view_distance_input.setPlaceholderText("500-5000")
        self.crossplay_checkbox = QCheckBox("Enable Crossplay")
        self.disable_3rd_person_checkbox = QCheckBox("Disable Third Person")
        self.battleye_checkbox = QCheckBox("Enable BattlEye")
        self.von_disable_ui_checkbox = QCheckBox("Disable VON UI")
        self.von_disable_direct_speech_checkbox = QCheckBox("Disable Direct Speech UI")
        self.von_transmit_cross_faction_checkbox = QCheckBox("Allow Cross-Faction VON Transmit")
        self.config_layout.addWidget(QLabel("Max View Distance (500-10000):"))
        self.config_layout.addWidget(self.view_distance_input)
        self.config_layout.addWidget(QLabel("Min Grass Distance (50-150):"))
        self.config_layout.addWidget(self.grass_distance_input)
        self.config_layout.addWidget(QLabel("Network View Distance (500-5000):"))
        self.config_layout.addWidget(self.network_view_distance_input)
        # Checkboxes with default values
        crossplay_layout = QHBoxLayout()
        crossplay_layout.addWidget(self.crossplay_checkbox)
        crossplay_layout.addWidget(QLabel("(Default: False)"))
        crossplay_layout.addStretch()
        self.config_layout.addLayout(crossplay_layout)
        third_person_layout = QHBoxLayout()
        third_person_layout.addWidget(self.disable_3rd_person_checkbox)
        third_person_layout.addWidget(QLabel("(Default: False)"))
        third_person_layout.addStretch()
        self.config_layout.addLayout(third_person_layout)
        battleye_layout = QHBoxLayout()
        battleye_layout.addWidget(self.battleye_checkbox)
        battleye_layout.addWidget(QLabel("(Default: True)"))
        battleye_layout.addStretch()
        self.config_layout.addLayout(battleye_layout)
        von_ui_layout = QHBoxLayout()
        von_ui_layout.addWidget(self.von_disable_ui_checkbox)
        von_ui_layout.addWidget(QLabel("(Default: False)"))
        von_ui_layout.addStretch()
        self.config_layout.addLayout(von_ui_layout)
        von_direct_speech_layout = QHBoxLayout()
        von_direct_speech_layout.addWidget(self.von_disable_direct_speech_checkbox)
        von_direct_speech_layout.addWidget(QLabel("(Default: False)"))
        von_direct_speech_layout.addStretch()
        self.config_layout.addLayout(von_direct_speech_layout)
        von_transmit_layout = QHBoxLayout()
        von_transmit_layout.addWidget(self.von_transmit_cross_faction_checkbox)
        von_transmit_layout.addWidget(QLabel("(Default: False)"))
        von_transmit_layout.addStretch()
        self.config_layout.addLayout(von_transmit_layout)

        # Operating Settings
        self.join_queue_size_input = QLineEdit()
        self.join_queue_size_input.setPlaceholderText("0-100")
        self.config_layout.addWidget(QLabel("Join Queue Max Size (0-100):"))
        self.config_layout.addWidget(self.join_queue_size_input)

        # Save and Review Buttons
        button_layout = QHBoxLayout()
        self.save_config_button = QPushButton("Save Configuration")
        self.review_config_button = QPushButton("Review Config")
        self.save_config_button.clicked.connect(self.save_config)
        self.review_config_button.clicked.connect(self.review_config)
        button_layout.addWidget(self.save_config_button)
        button_layout.addWidget(self.review_config_button)
        self.config_layout.addLayout(button_layout)
        self.config_layout.addStretch()
        self.tabs.addTab(self.config_scroll, "Server Config")

        # Mod Management Tab
        self.mods_tab = QWidget()
        self.mods_layout = QVBoxLayout(self.mods_tab)
        self.mods_scroll = QScrollArea()
        self.mods_scroll.setWidgetResizable(True)
        self.mods_container = QWidget()
        self.mods_container_layout = QVBoxLayout(self.mods_container)
        self.mods_scroll.setWidget(self.mods_container)
        self.mods_layout.addWidget(QLabel("Mod Management:"))
        self.mods_layout.addWidget(self.mods_scroll)

        # Mod Action Buttons
        button_layout = QHBoxLayout()
        self.add_mod_button = QPushButton("Add Mod")
        self.apply_mods_button = QPushButton("Apply Mod Changes")
        self.sync_mods_button = QPushButton("Sync Mod Names")
        self.disable_mods_button = QPushButton("Disable All Mods")
        self.enable_mods_button = QPushButton("Enable All Mods")
        self.add_mod_button.clicked.connect(self.add_mod)
        self.apply_mods_button.clicked.connect(self.apply_mod_changes)
        self.sync_mods_button.clicked.connect(self.sync_mods)
        self.disable_mods_button.clicked.connect(self.disable_mods)
        self.enable_mods_button.clicked.connect(self.enable_mods)
        button_layout.addWidget(self.add_mod_button)
        button_layout.addWidget(self.apply_mods_button)
        button_layout.addWidget(self.sync_mods_button)
        button_layout.addWidget(self.disable_mods_button)
        button_layout.addWidget(self.enable_mods_button)
        self.mods_layout.addLayout(button_layout)

        # Review Config Button
        self.mod_review_button = QPushButton("Review Config")
        self.mod_review_button.clicked.connect(self.review_config)
        self.mods_layout.addWidget(self.mod_review_button)
        self.tabs.addTab(self.mods_tab, "Mod Management")

        # Initial updates
        self.load_config()
        self.update_mods_display()
        self.apply_light_theme()

    def apply_light_theme(self):
        palette = QPalette()
        palette.setColor(QPalette.Window, QColor(255, 255, 255))
        palette.setColor(QPalette.WindowText, QColor(0, 0, 0))
        palette.setColor(QPalette.Base, QColor(255, 255, 255))
        palette.setColor(QPalette.AlternateBase, QColor(245, 245, 245))
        palette.setColor(QPalette.Text, QColor(0, 0, 0))
        palette.setColor(QPalette.Button, QColor(240, 240, 240))
        palette.setColor(QPalette.ButtonText, QColor(0, 0, 0))
        palette.setColor(QPalette.Highlight, QColor(0, 120, 215))
        palette.setColor(QPalette.HighlightedText, QColor(255, 255, 255))
        QApplication.instance().setPalette(palette)
        self.start_button.setStyleSheet("background-color: #00FF00; color: #000000;")
        self.stop_button.setStyleSheet("background-color: #FF0000; color: #000000;")
        self.restart_button.setStyleSheet("background-color: #FFFF00; color: #000000;")
        self.disable_mods_button.setStyleSheet("background-color: #FF0000; color: #000000;")
        self.enable_mods_button.setStyleSheet("background-color: #00FF00; color: #000000;")
        self.update_status_button_color()

    def apply_dark_theme(self):
        palette = QPalette()
        palette.setColor(QPalette.Window, QColor(46, 46, 46))
        palette.setColor(QPalette.WindowText, QColor(255, 255, 255))
        palette.setColor(QPalette.Base, QColor(60, 60, 60))
        palette.setColor(QPalette.AlternateBase, QColor(50, 50, 50))
        palette.setColor(QPalette.Text, QColor(255, 255, 255))
        palette.setColor(QPalette.Button, QColor(70, 70, 70))
        palette.setColor(QPalette.ButtonText, QColor(255, 255, 255))
        palette.setColor(QPalette.Highlight, QColor(0, 120, 215))
        palette.setColor(QPalette.HighlightedText, QColor(255, 255, 255))
        QApplication.instance().setPalette(palette)
        self.start_button.setStyleSheet("background-color: #00CC00; color: #000000;")
        self.stop_button.setStyleSheet("background-color: #CC0000; color: #000000;")
        self.restart_button.setStyleSheet("background-color: #CCCC00; color: #000000;")
        self.disable_mods_button.setStyleSheet("background-color: #CC0000; color: #000000;")
        self.enable_mods_button.setStyleSheet("background-color: #00CC00; color: #000000;")
        self.update_status_button_color()

    def toggle_theme(self):
        self.is_dark_theme = not self.is_dark_theme
        if self.is_dark_theme:
            self.apply_dark_theme()
            self.theme_button.setText("Switch to Light Theme")
        else:
            self.apply_light_theme()
            self.theme_button.setText("Switch to Dark Theme")

    def start_logging(self):
        self.log_window.clear()
        self.log_process.start("journalctl --user -u arma.service -f")
        if not self.log_process.waitForStarted():
            self.log_window.append("Error: Failed to start journalctl for logging.")

    def handle_log_output(self):
        data = self.log_process.readAllStandardOutput().data().decode()
        self.log_window.append(data.strip())
        self.log_window.verticalScrollBar().setValue(self.log_window.verticalScrollBar().maximum())

    def closeEvent(self, event):
        if self.log_process.state() != QProcess.NotRunning:
            self.log_process.terminate()
            if not self.log_process.waitForFinished(2000):
                self.log_process.kill()
        event.accept()

    def run_command(self, command):
        try:
            result = subprocess.run(command, shell=True, capture_output=True, text=True)
            return result.returncode == 0, result.stdout + result.stderr
        except Exception as e:
            return False, str(e)

    def update_status_button_color(self):
        success, output = self.run_command("systemctl --user is-active --quiet arma.service && echo 'active' || echo 'inactive'")
        if success and output.strip() == "active":
            self.status_button.setStyleSheet("background-color: #00FF00; color: #000000; font-size: 8pt;")
        else:
            self.status_button.setStyleSheet("background-color: #FF0000; color: #000000; font-size: 8pt;")

    def start_service(self):
        success, output = self.run_command("systemctl --user start arma.service")
        QMessageBox.information(self, "Service", "Service started" if success else f"Error: {output}")
        self.update_status_button_color()

    def stop_service(self):
        success, output = self.run_command("systemctl --user stop arma.service")
        QMessageBox.information(self, "Service", "Service stopped" if success else f"Error: {output}")
        self.update_status_button_color()

    def restart_service(self):
        success, output = self.run_command("systemctl --user restart arma.service")
        QMessageBox.information(self, "Service", "Service restarted" if success else f"Error: {output}")
        self.update_status_button_color()

    def show_status(self):
        success, output = self.run_command("systemctl --user is-active --quiet arma.service && echo 'Running' || echo 'Stopped'")
        if success:
            QMessageBox.information(self, "Service Status", output.strip())
        else:
            QMessageBox.critical(self, "Service Status", f"Error: {output}")

    def load_config(self):
        if not os.path.exists(self.config_file):
            QMessageBox.critical(self, "Error", f"Config file {self.config_file} not found.")
            return
        try:
            with open(self.config_file, 'r') as f:
                config = json.load(f)
            self.ip_input.setText(config.get("publicAddress", ""))
            self.port_input.setText(str(config.get("publicPort", 2001)))
            self.name_input.setText(config.get("game", {}).get("name", ""))
            self.game_password_input.setText(config.get("game", {}).get("password", ""))
            self.admin_password_input.setText(config.get("game", {}).get("passwordAdmin", ""))
            admins = config.get("game", {}).get("admins", [])
            self.admins_input.setText("\n".join(admins))
            current_scenario = config.get("game", {}).get("scenarioId", "")
            scenario_found = False
            for i, (scenario_id, desc) in enumerate(self.scenarios):
                if scenario_id == current_scenario:
                    self.scenario_combo.setCurrentIndex(i)
                    scenario_found = True
                    break
            if not scenario_found:
                self.custom_scenario_input.setText(current_scenario)
            else:
                self.custom_scenario_input.clear()
            self.max_players_input.setText(str(config.get("game", {}).get("maxPlayers", 6)))
            self.crossplay_checkbox.setChecked(config.get("game", {}).get("crossPlatform", False))
            game_props = config.get("game", {}).get("gameProperties", {})
            self.view_distance_input.setText(str(game_props.get("serverMaxViewDistance", 1600)))
            self.grass_distance_input.setText(str(game_props.get("serverMinGrassDistance", 50)))
            self.network_view_distance_input.setText(str(game_props.get("networkViewDistance", 1500)))
            self.disable_3rd_person_checkbox.setChecked(game_props.get("disableThirdPerson", False))
            self.battleye_checkbox.setChecked(game_props.get("battlEye", False))
            self.von_disable_ui_checkbox.setChecked(game_props.get("VONDisableUI", False))
            self.von_disable_direct_speech_checkbox.setChecked(game_props.get("VONDisableDirectSpeechUI", False))
            self.von_transmit_cross_faction_checkbox.setChecked(game_props.get("VONCanTransmitCrossFaction", False))
            operating = config.get("operating", {}).get("joinQueue", {})
            self.join_queue_size_input.setText(str(operating.get("maxSize", 0)))
        except Exception as e:
            QMessageBox.critical(self, "Error", f"Failed to load config: {e}")

    def validate_ip(self, ip):
        if not ip:
            return False
        try:
            octets = ip.split('.')
            if len(octets) != 4:
                return False
            for octet in octets:
                if not octet.isdigit() or int(octet) < 0 or int(octet) > 255:
                    return False
            return True
        except:
            return False

    def validate_integer_input(self, value, field_name, min_val, max_val):
        try:
            val = int(value)
            if val < min_val or val > max_val:
                return False, f"{field_name} must be between {min_val} and {max_val}."
            return True, ""
        except ValueError:
            return False, f"{field_name} must be a valid integer."

    def validate_admins(self, admins_text):
        uuid_pattern = re.compile(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
        guids = [guid.strip() for guid in admins_text.split('\n') if guid.strip()]
        if len(guids) > 20:
            return False, "Maximum 20 Player IdentityIds allowed."
        invalid_guids = []
        for guid in guids:
            if not uuid_pattern.match(guid):
                invalid_guids.append(guid)
        if invalid_guids:
            return False, f"Invalid Player IdentityIds (must be 36-character UUIDs): {', '.join(invalid_guids)}"
        return True, guids

    def validate_scenario_id(self, scenario_id):
        """Validate the scenarioId format (e.g., {UUID}Missions/...)."""
        if not scenario_id:
            return True, ""  # Empty is valid (falls back to dropdown)
        pattern = re.compile(r'^\{[0-9A-Fa-f]{16}\}Missions/[\w-]+\.conf$')
        if pattern.match(scenario_id):
            return True, ""
        return False, "Invalid Scenario ID format. Expected: {16-character hex UUID}Missions/<name>.conf"

    def save_config(self):
        if not os.path.exists(self.config_file):
            QMessageBox.critical(self, "Error", f"Config file {self.config_file} not found.")
            return
        if not self.validate_ip(self.ip_input.text()):
            QMessageBox.critical(self, "Error", "Invalid IP address format (e.g., 123.123.123.123).")
            return
        if not self.admin_password_input.text():
            QMessageBox.critical(self, "Error", "Admin password cannot be empty.")
            return

        validations = [
            (self.port_input.text(), "Public Port", 1024, 65535),
            (self.max_players_input.text(), "Max Players", 2, 128),
            (self.view_distance_input.text(), "Max View Distance", 500, 10000),
            (self.grass_distance_input.text(), "Min Grass Distance", 50, 150),
            (self.network_view_distance_input.text(), "Network View Distance", 500, 5000),
            (self.join_queue_size_input.text(), "Join Queue Max Size", 0, 100),
        ]
        for value, field_name, min_val, max_val in validations:
            is_valid, error_msg = self.validate_integer_input(value, field_name, min_val, max_val)
            if not is_valid:
                QMessageBox.critical(self, "Error", error_msg)
                return

        is_valid, result = self.validate_admins(self.admins_input.toPlainText())
        if not is_valid:
            QMessageBox.critical(self, "Error", result)
            return
        admin_guids = result

        custom_scenario = self.custom_scenario_input.text().strip()
        is_valid, error_msg = self.validate_scenario_id(custom_scenario)
        if custom_scenario and not is_valid:
            QMessageBox.critical(self, "Error", error_msg)
            return

        try:
            with open(self.config_file, 'r') as f:
                config = json.load(f)
            config["publicAddress"] = self.ip_input.text()
            config["publicPort"] = int(self.port_input.text())
            config.setdefault("game", {})
            config["game"]["name"] = self.name_input.text() or "Default Server"
            config["game"]["password"] = self.game_password_input.text()
            config["game"]["passwordAdmin"] = self.admin_password_input.text()
            config["game"]["admins"] = admin_guids
            config["game"]["scenarioId"] = custom_scenario if custom_scenario else self.scenarios[self.scenario_combo.currentIndex()][0]
            config["game"]["maxPlayers"] = int(self.max_players_input.text())
            config["game"]["crossPlatform"] = self.crossplay_checkbox.isChecked()
            config["game"].setdefault("gameProperties", {})
            config["game"]["gameProperties"]["serverMaxViewDistance"] = int(self.view_distance_input.text())
            config["game"]["gameProperties"]["serverMinGrassDistance"] = int(self.grass_distance_input.text())
            config["game"]["gameProperties"]["networkViewDistance"] = int(self.network_view_distance_input.text())
            config["game"]["gameProperties"]["disableThirdPerson"] = self.disable_3rd_person_checkbox.isChecked()
            config["game"]["gameProperties"]["battlEye"] = self.battleye_checkbox.isChecked()
            config["game"]["gameProperties"]["VONDisableUI"] = self.von_disable_ui_checkbox.isChecked()
            config["game"]["gameProperties"]["VONDisableDirectSpeechUI"] = self.von_disable_direct_speech_checkbox.isChecked()
            config["game"]["gameProperties"]["VONCanTransmitCrossFaction"] = self.von_transmit_cross_faction_checkbox.isChecked()
            config.setdefault("operating", {})
            config["operating"].setdefault("joinQueue", {})
            config["operating"]["joinQueue"]["maxSize"] = int(self.join_queue_size_input.text())
            tmp_file = "/tmp/server.json.tmp"
            with open(tmp_file, 'w') as f:
                json.dump(config, f)
            success, output = self.run_command(f"jq . {tmp_file} > {self.config_file}")
            if success:
                QMessageBox.information(self, "Success", "Configuration saved. Restart service to apply changes.")
            else:
                QMessageBox.critical(self, "Error", f"Failed to save config: {output}")
        except Exception as e:
            QMessageBox.critical(self, "Error", f"Failed to save config: {e}")

    def review_config(self):
        if not os.path.exists(self.config_file):
            QMessageBox.critical(self, "Error", f"Config file {self.config_file} not found.")
            return
        success, output = self.run_command(f"jq . {self.config_file}")
        if success:
            dialog = ConfigDialog(output, self)
            dialog.exec_()
        else:
            QMessageBox.critical(self, "Error", f"Failed to read config: {output}")

    def update_mods_display(self):
        for i in reversed(range(self.mods_container_layout.count())):
            widget = self.mods_container_layout.itemAt(i).widget()
            if widget:
                widget.deleteLater()

        if not os.path.exists(self.config_file):
            self.mods_container_layout.addWidget(QLabel("Error: server.json not found."))
            return
        if not os.path.exists(self.addons_dir):
            self.mods_container_layout.addWidget(QLabel("Warning: Addons directory not found."))
            return

        try:
            success, output = self.run_command(f"jq -c '.game.mods // []' {self.config_file}")
            if not success:
                self.mods_container_layout.addWidget(QLabel(f"Error loading mods: {output}"))
                return
            current_mods = json.loads(output)

            self.meta_data = {}
            self.installed_mods = set()
            meta_files = subprocess.check_output(
                f"find {self.addons_dir} -type f -name 'meta' -not -path '*/core/*' -not -path '*/data/*'",
                shell=True, text=True
            ).splitlines()
            for meta_file in meta_files:
                success, meta_output = self.run_command(f"jq -c . {meta_file}")
                if success:
                    meta = json.loads(meta_output)
                    mod_id = meta.get("meta", {}).get("id")
                    if mod_id and mod_id != "null":
                        name = meta.get("meta", {}).get("name", "Unknown")
                        version = meta.get("meta", {}).get("versions", [{}])[0].get("version", "Unknown")
                        self.meta_data[mod_id] = (name, version)
                        self.installed_mods.add(mod_id)

            self.active_mods = current_mods
            self.mod_checkboxes = {}
            active_mod_ids = {mod.get("modId", "") for mod in current_mods}

            all_mods = []
            for mod in current_mods:
                mod_id = mod.get("modId", "")
                all_mods.append((mod_id, mod.get("name", "Unknown"), True))
            for mod_id in self.installed_mods - active_mod_ids:
                all_mods.append((mod_id, self.meta_data.get(mod_id, ("Unknown", "Unknown"))[0], False))

            for mod_id, mod_name, is_active in all_mods:
                meta_info = self.meta_data.get(mod_id, (mod_name, "Unknown"))
                checkbox = QCheckBox(f"Enable: {mod_id} ({meta_info[0]}, Version: {meta_info[1]})")
                checkbox.setChecked(is_active)
                self.mod_checkboxes[mod_id] = checkbox
                self.mods_container_layout.addWidget(checkbox)

        except Exception as e:
            self.mods_container_layout.addWidget(QLabel(f"Error: {e}"))

    def add_mod(self):
        dialog = AddModsDialog(self)
        if dialog.exec_():
            mod_ids = dialog.get_mod_ids()
            if not mod_ids:
                QMessageBox.warning(self, "Warning", "No mod IDs entered.")
                return

            valid_mods = []
            invalid_mods = []
            for mod_id in mod_ids:
                if len(mod_id) == 16 and mod_id.isalnum():
                    valid_mods.append(mod_id)
                else:
                    invalid_mods.append(mod_id)

            if invalid_mods:
                QMessageBox.critical(self, "Error", f"Invalid mod IDs (must be 16 alphanumeric characters):\n{', '.join(invalid_mods)}")
                if not valid_mods:
                    return

            mods_to_add = [{"modId": mod_id, "name": "Unknown"} for mod_id in valid_mods]
            success, output = self.run_command(
                f"jq '.game.mods += {json.dumps(mods_to_add)} | .game.mods |= unique_by(.modId)' {self.config_file} > /tmp/mods.json && mv /tmp/mods.json {self.config_file}"
            )
            if success:
                QMessageBox.information(
                    self,
                    "Success",
                    f"Added {len(valid_mods)} mod(s). Start or restart the service to download mods, then click 'Sync Mod Names' to update names."
                )
                self.update_mods_display()
            else:
                QMessageBox.critical(self, "Error", f"Failed to add mods: {output}")

    def apply_mod_changes(self):
        new_mods = []
        for mod_id, checkbox in self.mod_checkboxes.items():
            if checkbox.isChecked():
                mod_name = self.meta_data.get(mod_id, ("Unknown", "Unknown"))[0]
                for mod in self.active_mods:
                    if mod.get("modId") == mod_id:
                        mod_name = mod.get("name", mod_name)
                        break
                new_mods.append({"modId": mod_id, "name": mod_name})

        success, output = self.run_command(
            f"echo '{json.dumps({'game': {'mods': new_mods}})}' | jq '.game.mods' > /tmp/mods.json && "
            f"jq --slurpfile mods /tmp/mods.json '.game.mods = $mods[0]' {self.config_file} > /tmp/server.json && mv /tmp/server.json {self.config_file}"
        )
        if success:
            QMessageBox.information(self, "Success", "Mod changes applied.")
            self.update_mods_display()
        else:
            QMessageBox.critical(self, "Error", f"Failed to apply mod changes: {output}")

    def sync_mods(self):
        if not self.active_mods:
            QMessageBox.warning(self, "Warning", "No mods in server.json to sync.")
            return
        if not os.path.exists(self.addons_dir):
            QMessageBox.warning(self, "Warning", f"No mod metadata available in {self.addons_dir}.")
            return
        try:
            meta_data = {}
            meta_files = subprocess.check_output(
                f"find {self.addons_dir} -type f -name 'meta' -not -path '*/core/*' -not -path '*/data/*'",
                shell=True, text=True
            ).splitlines()
            for meta_file in meta_files:
                success, meta_output = self.run_command(f"jq -c . {meta_file}")
                if success:
                    meta = json.loads(meta_output)
                    mod_id = meta.get("meta", {}).get("id")
                    if mod_id and mod_id != "null":
                        meta_data[mod_id] = meta.get("meta", {}).get("name", "Unknown")
            new_mods = []
            for mod in self.active_mods:
                mod_id = mod.get("modId", "")
                mod_name = meta_data.get(mod_id, mod.get("name", "Unknown"))
                new_mods.append({"modId": mod_id, "name": mod_name})
            success, output = self.run_command(
                f"echo '{json.dumps({'game': {'mods': new_mods}})}' | jq '.game.mods' > /tmp/mods.json && "
                f"jq --slurpfile mods /tmp/mods.json '.game.mods = $mods[0]' {self.config_file} > /tmp/server.json && mv /tmp/server.json {self.config_file}"
            )
            if success:
                QMessageBox.information(self, "Success", "Mod names synced with metadata.")
                self.update_mods_display()
            else:
                QMessageBox.critical(self, "Error", f"Failed to sync mods: {output}")
        except Exception as e:
            QMessageBox.critical(self, "Error", f"Error syncing mods: {e}")

    def disable_mods(self):
        reply = QMessageBox.question(
            self,
            "Confirm Disable All Mods",
            "Are you sure you want to disable all mods?\nThis will remove all mods from the server configuration.",
            QMessageBox.Yes | QMessageBox.No,
            QMessageBox.No
        )
        if reply != QMessageBox.Yes:
            return

        success, output = self.run_command(
            f"jq '.game.mods = []' {self.config_file} > /tmp/server.json && mv /tmp/server.json {self.config_file}"
        )
        if success:
            QMessageBox.information(self, "Success", "All mods disabled.")
            self.update_mods_display()
        else:
            QMessageBox.critical(self, "Error", f"Failed to disable mods: {output}")

    def enable_mods(self):
        reply = QMessageBox.question(
            self,
            "Confirm Enable All Mods",
            "Are you sure you want to enable all mods?\nThis will add all installed and previously configured mods to the server.",
            QMessageBox.Yes | QMessageBox.No,
            QMessageBox.No
        )
        if reply != QMessageBox.Yes:
            return

        if not os.path.exists(self.config_file):
            QMessageBox.critical(self, "Error", f"Config file {self.config_file} not found.")
            return
        if not os.path.exists(self.addons_dir):
            QMessageBox.warning(self, "Warning", f"No mod metadata available in {self.addons_dir}.")
            return

        try:
            # Load current mods from server.json
            success, output = self.run_command(f"jq -c '.game.mods // []' {self.config_file}")
            if not success:
                QMessageBox.critical(self, "Error", f"Failed to load mods: {output}")
                return
            current_mods = json.loads(output)
            current_mod_ids = {mod.get("modId", "") for mod in current_mods}

            # Load installed mods from addons directory
            meta_data = {}
            installed_mod_ids = set()
            meta_files = subprocess.check_output(
                f"find {self.addons_dir} -type f -name 'meta' -not -path '*/core/*' -not -path '*/data/*'",
                shell=True, text=True
            ).splitlines()
            for meta_file in meta_files:
                success, meta_output = self.run_command(f"jq -c . {meta_file}")
                if success:
                    meta = json.loads(meta_output)
                    mod_id = meta.get("meta", {}).get("id")
                    if mod_id and mod_id != "null":
                        name = meta.get("meta", {}).get("name", "Unknown")
                        meta_data[mod_id] = name
                        installed_mod_ids.add(mod_id)

            # Combine all mod IDs
            all_mod_ids = current_mod_ids | installed_mod_ids

            # Create new mods list
            new_mods = []
            for mod_id in all_mod_ids:
                # Prefer name from current_mods if available, else metadata, else "Unknown"
                mod_name = "Unknown"
                for mod in current_mods:
                    if mod.get("modId") == mod_id:
                        mod_name = mod.get("name", "Unknown")
                        break
                if mod_id in meta_data:
                    mod_name = meta_data[mod_id]
                new_mods.append({"modId": mod_id, "name": mod_name})

            # Save to server.json
            success, output = self.run_command(
                f"echo '{json.dumps({'game': {'mods': new_mods}})}' | jq '.game.mods' > /tmp/mods.json && "
                f"jq --slurpfile mods /tmp/mods.json '.game.mods = $mods[0]' {self.config_file} > /tmp/server.json && mv /tmp/server.json {self.config_file}"
            )
            if success:
                QMessageBox.information(self, "Success", f"All mods ({len(new_mods)}) enabled.")
                self.update_mods_display()
            else:
                QMessageBox.critical(self, "Error", f"Failed to enable mods: {output}")
        except Exception as e:
            QMessageBox.critical(self, "Error", f"Error enabling mods: {e}")

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = ArmaServerControlApp()
    window.show()
    sys.exit(app.exec_())
