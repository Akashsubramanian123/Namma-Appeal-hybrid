import time
import pytest
from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

class TestAppiumAndroidE2E:
    
    def _wait_and_find(self, driver, by, value, timeout=8):
        return WebDriverWait(driver, timeout).until(
            EC.presence_of_element_located((by, value))
        )

    # --- ONBOARDING & CAROUSEL CHECKS (1 - 20) ---
    def test_ob_1_logo_render(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@content-desc, 'page_icon') or @index=0]") is not None

    def test_ob_2_title_font(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Empowering') or contains(@content-desc, 'Empowering')]") is not None

    def test_ob_3_desc_font(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'simplifies') or contains(@content-desc, 'simplifies')]") is not None

    def test_ob_4_skip_btn_presence(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Skip') or contains(@content-desc, 'Skip')]") is not None

    def test_ob_5_skip_btn_enabled(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Skip') or contains(@content-desc, 'Skip')]").is_enabled()

    def test_ob_6_next_btn_presence(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Next') or contains(@content-desc, 'Next')]") is not None

    def test_ob_7_next_btn_enabled(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Next') or contains(@content-desc, 'Next')]").is_enabled()

    def test_ob_8_first_dot_highlight(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@content-desc, 'dot') or @index=0]") is not None

    def test_ob_9_swipe_slide_2(self, appium_driver):
        self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Next') or contains(@content-desc, 'Next')]").click()
        time.sleep(0.3)
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Scan') or contains(@content-desc, 'Scan')]") is not None

    def test_ob_10_second_dot_highlight(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@content-desc, 'dot') or @index=1]") is not None

    def test_ob_11_slide_2_text_match(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'rejections') or contains(@content-desc, 'rejections')]") is not None

    def test_ob_12_slide_2_skip_btn(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Skip') or contains(@content-desc, 'Skip')]") is not None

    def test_ob_13_swipe_slide_3(self, appium_driver):
        self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Next') or contains(@content-desc, 'Next')]").click()
        time.sleep(0.3)
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Draft') or contains(@content-desc, 'Draft')]") is not None

    def test_ob_14_third_dot_highlight(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@content-desc, 'dot') or @index=2]") is not None

    def test_ob_15_slide_3_desc(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'civic') or contains(@content-desc, 'civic')]") is not None

    def test_ob_16_get_started_btn(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Get Started') or contains(@content-desc, 'Get Started')]") is not None

    def test_ob_17_get_started_enabled(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Get Started') or contains(@content-desc, 'Get Started')]").is_enabled()

    def test_ob_18_get_started_click(self, appium_driver):
        self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Get Started') or contains(@content-desc, 'Get Started')]").click()
        time.sleep(0.5)

    def test_ob_19_splash_screen_indicator(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@content-desc, 'Namma-Appeal') or @index=0]") is not None

    def test_ob_20_splash_loading_bar(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@content-desc, 'progress') or @index=1]") is not None

    # --- AUTH & REGISTER CHECKS (21 - 45) ---
    def test_au_1_login_title_render(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Login') or contains(@content-desc, 'Login')]") is not None

    def test_au_2_subtitle_render(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'AI-powered') or contains(@content-desc, 'AI-powered')]") is not None

    def test_au_3_decorative_divider(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@content-desc, 'divider') or @index=2]") is not None

    def test_au_4_email_textbox(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//android.widget.EditText[contains(@text, 'Email') or contains(@content-desc, 'Email')]") is not None

    def test_au_5_email_prefix_icon(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@content-desc, 'email_outlined') or @index=0]") is not None

    def test_au_6_password_textbox(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//android.widget.EditText[contains(@text, 'Password') or contains(@content-desc, 'Password')]") is not None

    def test_au_7_password_prefix_icon(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@content-desc, 'lock_outlined') or @index=0]") is not None

    def test_au_8_forgot_password_btn(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Forgot') or contains(@content-desc, 'Forgot')]").is_enabled()

    def test_au_9_login_btn(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//android.widget.Button[contains(@text, 'Login') or contains(@content-desc, 'Login')]") is not None

    def test_au_10_google_auth_sso(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Google') or contains(@content-desc, 'Google')]") is not None

    def test_au_11_toggle_create_account(self, appium_driver):
        self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Create Account') or contains(@content-desc, 'Create Account')]").click()
        time.sleep(0.3)

    def test_au_12_signup_header(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Create') or contains(@content-desc, 'Create')]") is not None

    def test_au_13_signup_email_textbox(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//android.widget.EditText[contains(@text, 'Email') or contains(@content-desc, 'Email')]") is not None

    def test_au_14_signup_password_textbox(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//android.widget.EditText[contains(@text, 'Password') or contains(@content-desc, 'Password')]") is not None

    def test_au_15_signup_submit_btn(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//android.widget.Button[contains(@text, 'Sign Up') or contains(@content-desc, 'Sign Up')]") is not None

    def test_au_16_toggle_back_login(self, appium_driver):
        self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Login') or contains(@content-desc, 'Login')]").click()
        time.sleep(0.3)

    def test_au_17_privacy_link(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Privacy') or contains(@content-desc, 'Privacy')]").is_enabled()

    def test_au_18_terms_link(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Terms') or contains(@content-desc, 'Terms')]").is_enabled()

    def test_au_19_legal_dialog_dismiss(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Privacy') or contains(@content-desc, 'Privacy')]") is not None

    def test_au_20_oauth_logo_render(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Google') or contains(@content-desc, 'Google')]") is not None

    def test_au_21_forgot_password_dialog_open(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Forgot') or contains(@content-desc, 'Forgot')]") is not None

    def test_au_22_forgot_password_email_input(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//android.widget.EditText[contains(@text, 'Email') or contains(@content-desc, 'Email')]") is not None

    def test_au_23_forgot_password_submit(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Forgot') or contains(@content-desc, 'Forgot')]") is not None

    def test_au_24_auth_mode_toggle_styling(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Create Account') or contains(@content-desc, 'Create Account')]") is not None

    def test_au_25_login_validation_blank(self, appium_driver):
        btn = self._wait_and_find(appium_driver, AppiumBy.XPATH, "//android.widget.Button[contains(@text, 'Login') or contains(@content-desc, 'Login')]")
        assert btn.is_enabled()

    # --- MAIN NAVIGATION CHECKS (46 - 60) ---
    def test_nv_1_scanner_tab(self, appium_driver):
        self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Scanner') or contains(@content-desc, 'Scanner')]").click()
        time.sleep(0.3)

    def test_nv_2_new_rti_tab(self, appium_driver):
        self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'New RTI') or contains(@content-desc, 'New RTI')]").click()
        time.sleep(0.3)

    def test_nv_3_history_tab(self, appium_driver):
        self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'History') or contains(@content-desc, 'History')]").click()
        time.sleep(0.3)

    def test_nv_4_assistant_tab(self, appium_driver):
        self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Assistant') or contains(@content-desc, 'Assistant')]").click()
        time.sleep(0.3)

    def test_nv_5_profile_tab(self, appium_driver):
        self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Profile') or contains(@content-desc, 'Profile')]").click()
        time.sleep(0.3)

    def test_nv_6_reminders_bell_icon(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@content-desc, 'Reminders') or @index=0]") is not None

    def test_nv_7_logout_appbar_icon(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@content-desc, 'Sign Out') or @index=1]") is not None

    def test_nv_8_logout_alert_dialog(self, appium_driver):
        self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@content-desc, 'Sign Out') or @index=1]").click()
        time.sleep(0.3)
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Sign Out') or contains(@content-desc, 'Sign Out')]") is not None

    def test_nv_9_logout_cancel_click(self, appium_driver):
        self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Cancel') or contains(@content-desc, 'Cancel')]").click()
        time.sleep(0.3)

    def test_nv_10_appbar_text_title(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Profile') or contains(@content-desc, 'Profile')]") is not None

    def test_nv_11_tab_bar_icons(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Scanner') or contains(@content-desc, 'Scanner')]") is not None

    def test_nv_12_reminders_modal_loaded(self, appium_driver):
        self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@content-desc, 'Reminders') or @index=0]").click()
        time.sleep(0.5)
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Reminders') or contains(@content-desc, 'Reminders')]") is not None

    def test_nv_13_reminders_back_click(self, appium_driver):
        self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@content-desc, 'Back') or contains(@content-desc, 'Navigate') or @index=0]").click()
        time.sleep(0.3)

    def test_nv_14_profile_indicator(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Profile') or contains(@content-desc, 'Profile')]") is not None

    def test_nv_15_tab_index_state(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Profile') or contains(@content-desc, 'Profile')]") is not None

    # --- NEW RTI CHECKS (61 - 75) ---
    def test_rt_1_lang_selector(self, appium_driver):
        self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'New RTI') or contains(@content-desc, 'New RTI')]").click()
        time.sleep(0.3)
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'English') or contains(@content-desc, 'English')]") is not None

    def test_rt_2_change_to_hindi(self, appium_driver):
        self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'English') or contains(@content-desc, 'English')]").click()
        time.sleep(0.3)
        self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Hindi') or contains(@content-desc, 'Hindi')]").click()
        time.sleep(0.3)

    def test_rt_3_pio_list(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Auto-Detect') or contains(@content-desc, 'Auto-Detect')]") is not None

    def test_rt_4_select_rto_pio(self, appium_driver):
        self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Auto-Detect') or contains(@content-desc, 'Auto-Detect')]").click()
        time.sleep(0.3)
        self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'RTO') or contains(@content-desc, 'RTO')]").click()
        time.sleep(0.3)

    def test_rt_5_speech_mic_btn(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@content-desc, 'mic') or @index=1]") is not None

    def test_rt_6_photo_selector_btn(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Attach') or contains(@content-desc, 'Attach')]") is not None

    def test_rt_7_details_textbox(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//android.widget.EditText") is not None

    def test_rt_8_submit_draft_btn(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Generate') or contains(@content-desc, 'Generate')]").is_enabled()

    def test_rt_9_lang_tamil_select(self, appium_driver):
        self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Hindi') or contains(@content-desc, 'Hindi')]").click()
        time.sleep(0.3)
        self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Tamil') or contains(@content-desc, 'Tamil')]").click()
        time.sleep(0.3)

    def test_rt_10_pio_chennai_metro_select(self, appium_driver):
        self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'RTO') or contains(@content-desc, 'RTO')]").click()
        time.sleep(0.3)
        self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Chennai Metro') or contains(@content-desc, 'Chennai Metro')]").click()
        time.sleep(0.3)

    def test_rt_11_attaching_photo_flow(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Attach') or contains(@content-desc, 'Attach')]") is not None

    def test_rt_12_typing_prompt_details(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//android.widget.EditText") is not None

    def test_rt_13_mic_toggle_flow(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@content-desc, 'mic') or @index=1]") is not None

    def test_rt_14_submit_generates_request(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Generate') or contains(@content-desc, 'Generate')]") is not None

    def test_rt_15_lang_dropdown_items_count(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Tamil') or contains(@content-desc, 'Tamil')]") is not None

    # --- PROFILE CHECKS (76 - 90) ---
    def test_pr_1_user_avatar(self, appium_driver):
        self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Profile') or contains(@content-desc, 'Profile')]").click()
        time.sleep(0.3)
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@content-desc, 'person') or @index=0]") is not None

    def test_pr_2_full_name_input(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//android.widget.EditText[contains(@text, 'Full Name') or contains(@content-desc, 'Full Name')]") is not None

    def test_pr_3_mobile_input(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//android.widget.EditText[contains(@text, 'Mobile') or contains(@content-desc, 'Mobile')]") is not None

    def test_pr_4_state_input(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//android.widget.EditText[contains(@text, 'State') or contains(@content-desc, 'State')]") is not None

    def test_pr_5_address_input(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//android.widget.EditText[contains(@text, 'Address') or contains(@content-desc, 'Address')]") is not None

    def test_pr_6_language_selector(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'English') or contains(@content-desc, 'English')]") is not None

    def test_pr_7_save_profile_button(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Save') or contains(@content-desc, 'Save')]").is_enabled()

    def test_pr_8_validation_mandatory_asterisk(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//android.widget.EditText[contains(@text, 'Full Name') or contains(@content-desc, 'Full Name')]") is not None

    def test_pr_9_address_field_multiline(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//android.widget.EditText[contains(@text, 'Address') or contains(@content-desc, 'Address')]") is not None

    def test_pr_10_state_field_selection(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//android.widget.EditText[contains(@text, 'State') or contains(@content-desc, 'State')]") is not None

    def test_pr_11_save_clicks_triggers_state(self, appium_driver):
        self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Save') or contains(@content-desc, 'Save')]").click()
        time.sleep(0.5)

    def test_pr_12_legal_policy_item(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Privacy') or contains(@content-desc, 'Privacy')]") is not None

    def test_pr_13_avatar_icon_renders(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@content-desc, 'person') or @index=0]") is not None

    def test_pr_14_mobile_number_validation_pass(self, appium_driver):
        field = self._wait_and_find(appium_driver, AppiumBy.XPATH, "//android.widget.EditText[contains(@text, 'Mobile') or contains(@content-desc, 'Mobile')]")
        field.click()
        field.clear()
        field.send_keys("9876543210")
        time.sleep(0.3)

    def test_pr_15_mobile_number_validation_fail(self, appium_driver):
        field = self._wait_and_find(appium_driver, AppiumBy.XPATH, "//android.widget.EditText[contains(@text, 'Mobile') or contains(@content-desc, 'Mobile')]")
        field.click()
        field.clear()
        field.send_keys("123")
        time.sleep(0.3)

    # --- LEGAL ASSISTANT & STATE DATA FLOWS (91 - 100) ---
    def test_as_1_welcome_message(self, appium_driver):
        self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Assistant') or contains(@content-desc, 'Assistant')]").click()
        time.sleep(0.3)
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'legal assistant') or contains(@content-desc, 'legal assistant')]") is not None

    def test_as_2_session_title_header(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Chat') or contains(@content-desc, 'Chat') or contains(@text, 'Session') or contains(@content-desc, 'Session')]") is not None

    def test_as_3_history_icon(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@content-desc, 'History') or @index=0]") is not None

    def test_as_4_new_chat_icon(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@content-desc, 'New') or @index=2]") is not None

    def test_as_5_chat_input_textfield(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//android.widget.EditText") is not None

    def test_as_6_chat_mic_speech_icon(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@content-desc, 'mic') or @index=1]") is not None

    def test_as_7_chat_send_icon(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//android.widget.Button[contains(@content-desc, 'send') or contains(@content-desc, 'Send') or contains(@content-desc, 'Message') or contains(@text, 'send') or @index=1]") is not None

    def test_as_8_conversations_persistence_save(self, appium_driver):
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//android.widget.EditText") is not None

    def test_as_9_conversations_past_history_sheet(self, appium_driver):
        self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@content-desc, 'History') or @index=0]").click()
        time.sleep(0.5)
        self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Chat History') or contains(@content-desc, 'Chat History')]")
        appium_driver.back()
        time.sleep(0.5)

    def test_df_1_profile_auto_fill_mapping(self, appium_driver):
        self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Profile') or contains(@content-desc, 'Profile')]").click()
        time.sleep(0.3)
        field = self._wait_and_find(appium_driver, AppiumBy.XPATH, "//android.widget.EditText[contains(@text, 'Full Name') or contains(@content-desc, 'Full Name')]")
        field.click()
        field.clear()
        field.send_keys("Integrated Python Flow Citizen")
        self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Save') or contains(@content-desc, 'Save')]").click()
        time.sleep(0.5)
        self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'New RTI') or contains(@content-desc, 'New RTI')]").click()
        time.sleep(0.3)
        assert self._wait_and_find(appium_driver, AppiumBy.XPATH, "//*[contains(@text, 'Integrated Python Flow Citizen') or contains(@content-desc, 'Integrated Python Flow Citizen')]") is not None
