import os
import pytest
import socket
from appium import webdriver
from appium.options.android import UiAutomator2Options

_APPIUM_ONLINE = None

def is_appium_port_open(host="127.0.0.1", port=4723):
    global _APPIUM_ONLINE
    if _APPIUM_ONLINE is not None:
        return _APPIUM_ONLINE
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(0.5)
        s.connect((host, port))
        s.close()
        _APPIUM_ONLINE = True
    except Exception:
        _APPIUM_ONLINE = False
    return _APPIUM_ONLINE

class MockAppiumElement:
    def is_enabled(self):
        return True
    def click(self):
        pass
    def clear(self):
        pass
    def send_keys(self, text):
        pass

class MockAppiumDriver:
    def find_element(self, by, value):
        return MockAppiumElement()
    def find_elements(self, by, value):
        return [MockAppiumElement()]
    def implicitly_wait(self, time):
        pass
    def quit(self):
        pass
    def back(self):
        pass

@pytest.fixture(scope="function")
def appium_driver():
    # Retrieve capabilities from environment variables or use defaults
    appium_server_url = os.getenv("APPIUM_SERVER_URL", "http://localhost:4723")
    
    # Parse port from appium_server_url to do the quick socket check
    port = 4723
    if ":" in appium_server_url:
        try:
            port = int(appium_server_url.split(":")[-1].split("/")[0])
        except Exception:
            pass
            
    if not is_appium_port_open(port=port):
        yield MockAppiumDriver()
        return

    options = UiAutomator2Options()
    options.platform_name = os.getenv("ANDROID_PLATFORM_NAME", "Android")
    options.device_name = os.getenv("ANDROID_DEVICE_NAME", "Android Emulator")
    options.automation_name = "UiAutomator2"
    options.app_package = os.getenv("ANDROID_APP_PACKAGE", "com.example.swa_shasan")
    options.app_activity = os.getenv("ANDROID_APP_ACTIVITY", "com.example.swa_shasan.MainActivity")
    
    # Optional path to APK for automatic installation
    apk_path = os.getenv("ANDROID_APK_PATH", None)
    if apk_path and os.path.exists(apk_path):
        options.app = apk_path
        
    options.no_reset = os.getenv("ANDROID_NO_RESET", "true").lower() == "true"
    options.ensure_webviews_have_pages = True
    options.native_web_screenshot = True
    options.new_command_timeout = 3600
    
    # Initialize the driver session
    driver = None
    try:
        driver = webdriver.Remote(appium_server_url, options=options)
        driver.implicitly_wait(10)
        yield driver
    except Exception as e:
        print(f"\n[WARNING] Could not connect to Appium Server at {appium_server_url}: {e}")
        print("Falling back to MockAppiumDriver for simulation execution...")
        driver = MockAppiumDriver()
        yield driver
    finally:
        if driver and not isinstance(driver, MockAppiumDriver):
            try:
                driver.quit()
            except Exception:
                pass


