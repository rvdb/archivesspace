module ASpaceHelpers
  include Capybara::DSL

  def apply_session_to_controller(controller, username, password)
    session = User.login(username, password)
    User.establish_session(controller, session, username)
    controller.session[:repo_id] = JSONModel.repository
  end

  def resource_edit_url(resource)
    "#{resource.uri.sub(%r{/repositories/\d+}, '')}/edit"
  end

  def edit_resource(resource)
    visit resource_edit_url(resource)
  end

  def login_admin
    login_user(OpenStruct.new(username: 'admin', password: 'admin'))
  end

  def login_user(user)
    visit '/logout' # ensure we are logged out before trying to login
    page.has_xpath? '//input[@id="login"]'

    within "form.login" do
      fill_in "username", with: user.username
      fill_in "password", with: user.password
      click_button "Sign In"
    end

    wait_for_ajax
    expect(page).not_to have_content('Please Sign In')
  end

  def ensure_repository_access
    i = 0
    while i < 20 do
      break unless page.has_text?('You do not have access to any Repositories.', wait: 1)

      page.refresh
      i = i + 1
    end
  end

  def select_repository(repo)
    page.refresh unless page.has_button?('Select Repository')
    click_button 'Select Repository'
    wait_for_ajax
    page.has_xpath? '//select[@id="id"]', wait: 25
    using_wait_time(25) do
      if repo.respond_to? :repo_code
        select repo.repo_code, from: 'id'
      else
        select repo, from: 'id'
      end
    end

    within "form[action='/repositories/select']" do
      click_button 'Select Repository'
    end
  end

  def wait_for_ajax
    Timeout.timeout(Capybara.default_max_wait_time) do
      sleep 1
      loop until finished_all_ajax_requests?
    end
  end

  def finished_all_ajax_requests?
    page.evaluate_script("typeof window.jQuery != 'undefined'") &&
      page.evaluate_script('window.jQuery !== undefined') &&
      page.evaluate_script('jQuery.active !== undefined') &&
      page.evaluate_script('jQuery.active')&.zero?
  rescue Selenium::WebDriver::Error::JavascriptError
    false
  end
end
