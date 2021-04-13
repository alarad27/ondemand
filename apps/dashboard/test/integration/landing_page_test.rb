require 'html_helper'
require 'test_helper'

# Test the feature for configuring landing pages through ConfigurationSingleton#landing_page_layout.

# Note that the default layout (having no ConfigurationSingleton#landing_page_layout set)
# and variants (MOTD enabled/disabled, XDMOD & MOTD enabled/disabled and so on) are handled
# by pinned_apps_test.rb.
class LandingPageTest < ActionDispatch::IntegrationTest

  def setup
    Router.instance_variable_set('@pinned_apps', nil)
  end

  def teardown
    Router.instance_variable_set('@pinned_apps', nil)
  end

  def test_env
    {
      MOTD_FORMAT: 'osc',
      MOTD_PATH: Rails.root.join("test/fixtures/files/motd_valid").to_s,
      #this is going to fail, but that's OK - the widets will still appear
      OOD_XDMOD_HOST: "http://localhost",
    }
  end

  test "should show nothing when nothing is given" do
    # XDMOD here isn't really 
    Configuration.stubs(:landing_page_layout).returns({})

    get '/'

    assert_select 'div.row', 0
  end

  test "nil MOTD and pinned apps render empty elements" do
    Configuration.stubs(:landing_page_layout).returns({
      rows: [
        {
          columns: [
            {
              width: 8,
              widgets: 'motd'
            },
            {
              width: 4,
              widgets: 'pinned_apps'
            }
          ]
        }
      ]
    })

    get '/'

    assert_select 'div.row', 1
    assert_select 'div.row > div.col-md-8', 1
    assert_select 'div.row > div.col-md-4', 1

    motd =  css_select('div.row > div.col-md-8')
    pinned_apps = css_select('div.row > div.col-md-4')

    # they exist, but they're empty. No errors because you've configured to show them, 
    # but not configured to create them
    assert_equal motd.children.size, 1
    assert_equal motd.children.first.to_s.gsub(/[\s\n]/,''), ""
    assert_equal pinned_apps.children.size, 1
    assert_equal pinned_apps.children.first.to_s.gsub(/[\s\n]/,''), ""
  end

  test "shows MOTD a single row, single column" do
    Configuration.stubs(:landing_page_layout).returns({
      rows: [
        {
          columns: [
            {
              width: 12,
              widgets: 'motd'
            }
          ]
        }
      ]
    })

    with_modified_env(test_env) do
      get '/'
    end

    assert_response :success

    assert_select 'div.row', 1
    assert_select 'div.row > div.col-md-12', 1
    assert_select 'div.row > div.col-md-12 > div.motd', 3
    assert_select 'div.row > div.col-md-12 > div.motd > h4', 3
    assert_select 'div.row > div.col-md-12 > div.motd > div.motd_body', 3
  end

  test "shows widgets with one row and two columns" do
    Configuration.stubs(:landing_page_layout).returns({
      rows: [
        {
          columns: [
            {
              width: 8,
              widgets: 'motd'
            },
            {
              width: 4,
              widgets: ['xdmod_widget_job_efficiency', 'xdmod_widget_jobs']
            }
          ]
        }
      ]
    })

    with_modified_env(test_env) do
      get '/'
    end

    assert_select 'div.row', 1
    assert_select 'div.row > div.col-md-8', 1
    assert_select 'div.row > div.col-md-8 > div.motd', 3
    assert_select 'div.row > div.col-md-8 > div.motd > h4', 3
    assert_select 'div.row > div.col-md-8 > div.motd > div.motd_body', 3

    assert_select 'div.row > div.col-md-4', 1
    assert_select 'div.row > div.col-md-4 > div.xdmod', 2
    assert_select 'div.row > div.col-md-4 > div.xdmod > [id="jobsEfficiencyReportPanelDiv"]', 1
    assert_select 'div.row > div.col-md-4 > div.xdmod > [id="coreHoursEfficiencyReportPanelDiv"]', 1
    assert_select 'div.row > div.col-md-4 > div.xdmod > [id="jobsPanelDiv"]', 1
  end

  test "shows widgets on a second row" do
    SysRouter.stubs(:base_path).returns(Rails.root.join("test/fixtures/sys_with_gateway_apps"))
    OodAppkit.stubs(:clusters).returns(OodCore::Clusters.load_file("test/fixtures/config/clusters.d"))
    Configuration.stubs(:pinned_apps).returns([
      'sys/bc_jupyter',
      'sys/bc_paraview',
      'sys/bc_desktop/owens',
      'sys/pseudofun',
    ])
    Configuration.stubs(:landing_page_layout).returns({
      rows: [
        {
          columns: [
            {
              width: 8,
              widgets: 'motd'
            },
            {
              width: 4,
              widgets: ['xdmod_widget_job_efficiency', 'xdmod_widget_jobs']
            }
          ]
        },
        {
          columns: [
            {
              width: 12,
              widgets: 'pinned_apps'
            }
          ]
        }
      ]
    })

    with_modified_env(test_env) do
      get '/'
    end

    assert_response :success

    assert_select 'div.row', 3 # one extra row because pinned_apps makes rows for every 'group'
    assert_select 'div.row > div.col-md-8', 1
    assert_select 'div.row > div.col-md-8 > div.motd', 3
    assert_select 'div.row > div.col-md-8 > div.motd > h4', 3
    assert_select 'div.row > div.col-md-8 > div.motd > div.motd_body', 3

    assert_select 'div.row > div.col-md-4', 1
    assert_select 'div.row > div.col-md-4 > div.xdmod', 2
    assert_select 'div.row > div.col-md-4 > div.xdmod > [id="jobsEfficiencyReportPanelDiv"]', 1
    assert_select 'div.row > div.col-md-4 > div.xdmod > [id="coreHoursEfficiencyReportPanelDiv"]', 1
    assert_select 'div.row > div.col-md-4 > div.xdmod > [id="jobsPanelDiv"]', 1

    assert_select 'div.row > div.col-md-12', 1
    assert_select 'div.row > div.col-md-12 > div.row > div.col-sm-3.col-md-3', 4
    assert_select pinned_app_css_query("12", '/batch_connect/sys/bc_jupyter/session_contexts/new'), 1
    assert_select pinned_app_css_query("12", '/batch_connect/sys/bc_paraview/session_contexts/new'), 1
    assert_select pinned_app_css_query("12", '/apps/show/pseudofun'), 1
    assert_select pinned_app_css_query("12", '/batch_connect/sys/bc_desktop/owens/session_contexts/new'), 1
  end

  test "bad widgets don't throw errors" do
    Configuration.stubs(:landing_page_layout).returns({
      rows: [
        {
          columns: [
            {
              width: 6,
              widgets: 'this_widget_doesnt_exist'
            },
            {
              width: 6,
              widgets: 'syntax_error'
            }
          ]
        }
      ]
    })

    with_modified_env(test_env) do
      get '/'
    end
    
    assert_select 'div.row', 1
    assert_select 'div.row > div.col-md-6', 2

    error_widgets = css_select('div.row > div.col-md-6 > div.alert.alert-danger.card > div.card-body')
    assert_equal 2, error_widgets.size
    assert_equal true, /Missing partial dashboard\/_this_widget_doesnt_exist/.match?(error_widgets[0].text)
    assert_equal true, /undefined method `woops!'/.match?(error_widgets[1].text)
  end

  test "should render brand new widgets with shipped widgets" do
    Configuration.stubs(:landing_page_layout).returns({
      rows: [
        {
          columns: [
            {
              width: 6,
              widgets: 'test_partial'
            },
            {
              width: 6,
              widgets: 'motd'
            }
          ]
        }
      ]
    })

    with_modified_env(test_env) do
      get '/'
    end

    assert_select 'div.row', 1
    assert_select 'div.row > div.col-md-6', 2

    assert_select 'div.row > div.col-md-6 > div.motd', 3
    assert_select 'div.row > div.col-md-6 > div.motd > h4', 3
    assert_select 'div.row > div.col-md-6 > div.motd > div.motd_body', 3

    assert_select 'div.row > div.col-md-6 > #my-test-partial', 1
    actual_value = css_select('div.row > div.col-md-6 > #my-test-partial').text.gsub(/\n/,'').strip
    assert_equal "My Test Partial's now in the dashboard!", actual_value
  end
end