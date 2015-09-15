require 'test/unit'
require 'selenium-webdriver'

class TestSuite < Test::Unit::TestCase
  def setup
    @base_url = "http://fairdomhub.org/"
  end

  def test_suite
    puts "\nPlease provide the user name:"
    user_name = STDIN.gets.chomp
    puts "Please provide the password:"
    password = STDIN.noecho(&:gets).chomp
    for_firefox(user_name, password)
    for_chrome(user_name, password)
  end

  private

  def for_firefox(user_name, password)
    browser = Selenium::WebDriver.for :firefox
    browser.manage().window.maximize()
    login(browser, user_name, password)
    get_page(browser)
    create_page(browser)
    browser.quit
  end

  def for_chrome(user_name, password)
    driver_path = File.dirname(__FILE__) + "/drivers/chromedriver"
    Selenium::WebDriver::Chrome.driver_path = driver_path
    browser = Selenium::WebDriver.for :chrome
    browser.manage().window.maximize()
    login(browser, user_name, password)
    get_page(browser)
    create_page(browser)
    browser.quit
  end

  def get_page(browser)
    #homepage
    browser.get @base_url
    assert_equal('The SEEK',browser.title)

    #yellow pages
    browser.get @base_url + "programmes"
    assert_equal('The SEEK Programmes',browser.title)
    browser.get @base_url + "programmes/2"
    assert_equal('The SEEK Programmes',browser.title)
    browser.get @base_url + "people"
    assert_equal('The SEEK People',browser.title)
    browser.get @base_url + "people/372"
    assert_equal('The SEEK People',browser.title)
    browser.get @base_url + "projects"
    assert_equal('The SEEK Projects',browser.title)
    browser.get @base_url + "projects/19"
    assert_equal('The SEEK Projects',browser.title)
    browser.get @base_url + "institutions"
    assert_equal('The SEEK Institutions',browser.title)
    browser.get @base_url + "institutions/7"
    assert_equal('The SEEK Institutions',browser.title)

    #isa
    browser.get @base_url + "investigations"
    assert_equal('The SEEK Investigations',browser.title)
    browser.get @base_url + "investigations/56"
    assert_equal('The SEEK Investigations',browser.title)
    browser.get @base_url + "studies"
    assert_equal('The SEEK Studies',browser.title)
    browser.get @base_url + "studies/138"
    assert_equal('The SEEK Studies',browser.title)
    browser.get @base_url + "assays"
    assert_equal('The SEEK Assays',browser.title)
    browser.get @base_url + "assays/296"
    assert_equal('The SEEK Assays',browser.title)

    #assets
    browser.get @base_url + "data_files"
    assert_equal('The SEEK Data files',browser.title)
    browser.get @base_url + "data_files/1101"
    assert_equal('The SEEK Data files',browser.title)
    browser.get @base_url + "data_files/1101/explore?version=1"
    assert_equal('The SEEK Data files',browser.title)
    browser.get @base_url + "models"
    assert_equal('The SEEK Models',browser.title)
    browser.get @base_url + "models/138"
    assert_equal('The SEEK Models',browser.title)
    browser.get @base_url + "sops"
    assert_equal('The SEEK SOPs',browser.title)
    browser.get @base_url + "sops/203"
    assert_equal('The SEEK SOPs',browser.title)
    browser.get @base_url + "publications"
    assert_equal('The SEEK Publications',browser.title)
    browser.get @base_url + "publications/240"
    assert_equal('The SEEK Publications',browser.title)

    #biosamples
    browser.get @base_url + "biosamples"
    assert_equal('The SEEK Biosamples',browser.title)
    browser.get @base_url + "organisms/1933753700"
    assert_equal('The SEEK Organisms',browser.title)
    browser.get @base_url + "strains"
    assert_equal('The SEEK Strains',browser.title)
    browser.get @base_url + "strains/27"
    assert_equal('The SEEK Strains',browser.title)
    browser.get @base_url + "specimens"
    assert_equal('The SEEK Cell cultures',browser.title)
    browser.get @base_url + "specimens/2"
    assert_equal('The SEEK Cell cultures',browser.title)
    browser.get @base_url + "samples"
    assert_equal('The SEEK Samples',browser.title)
    browser.get @base_url + "samples/2"
    assert_equal('The SEEK Samples',browser.title)

    #activities
    browser.get @base_url + "presentations"
    assert_equal('The SEEK Presentations',browser.title)
    browser.get @base_url + "presentations/52"
    assert_equal('The SEEK Presentations',browser.title)
    browser.get @base_url + "presentations/52/content_blobs/2149/view_pdf_content"
    assert_equal('The SEEK : Viewing SeekNewFeaturesPalsParis2013.odp',browser.title)
    browser.get @base_url + "events"
    assert_equal('The SEEK Events',browser.title)
    browser.get @base_url + "events/26"
    assert_equal('The SEEK Events',browser.title)

    #help
    browser.get @base_url + "help/index"
    assert_equal('The SEEK Help',browser.title)
    browser.get @base_url + "help/faq"
    assert_equal('The SEEK Help',browser.title)
    browser.get @base_url + "help/templates"
    assert_equal('The SEEK Help',browser.title)
    browser.get @base_url + "help/isa-best-practice"
    assert_equal('The SEEK Help',browser.title)

    #tags
    browser.get @base_url + "tags/"
    assert_equal('The SEEK',browser.title)
    browser.get @base_url + "tags/19"
    assert_equal('The SEEK',browser.title)

    #imprint
    browser.get @base_url + "home/imprint"
    assert_equal('The SEEK',browser.title)
  end

  def login(browser, user_name, password)
    browser.get @base_url + "login"
    user_elelment = browser.find_element(:id, 'login')
    user_elelment.send_keys user_name
    password_element = browser.find_element(:id, 'password')
    password_element.send_keys password
    login_element = browser.find_element(:id, 'login_button')
    login_element.submit
    wait = Selenium::WebDriver::Wait.new(:timeout => 10) # seconds
    wait.until { browser.find_element(:id => "user-menu") }
  end

  def create_page(browser)
    #assets
    browser.get @base_url + "data_files/new"
    assert_not_nil browser.find_element(:id, 'data_file_title')
    browser.get @base_url + "models/new"
    assert_not_nil browser.find_element(:id, 'model_title')
    browser.get @base_url + "sops/new"
    assert_not_nil browser.find_element(:id, 'sop_title')
    browser.get @base_url + "publications/new"
    assert_not_nil browser.find_element(:id, 'protocol')

    #biosamples
    browser.get @base_url + "strains/new"
    assert_not_nil browser.find_element(:id, 'strain_title')
    browser.get @base_url + "specimens/new"
    assert_not_nil browser.find_element(:id, 'specimen_title')
    browser.get @base_url + "samples/new"
    assert_not_nil browser.find_element(:id, 'sample_title')

    #isa
    browser.get @base_url + "investigations/new"
    assert_not_nil browser.find_element(:id, 'investigation_title')
    browser.get @base_url + "studies/new"
    assert_not_nil browser.find_element(:id, 'study_title')
    browser.get @base_url + "assays/new?class=experimental"
    assert_not_nil browser.find_element(:id, 'assay_title')

    #activities
    browser.get @base_url + "presentations/new"
    assert_not_nil browser.find_element(:id, 'presentation_title')
    browser.get @base_url + "events/new"
    assert_not_nil browser.find_element(:id, 'event_title')
  end
end