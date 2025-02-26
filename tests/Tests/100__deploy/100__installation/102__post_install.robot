*** Settings ***
Documentation       Post install test cases that mainly verify OCP resources and objects
Library             String
Library             OperatingSystem
Library             OpenShiftCLI
Library             OpenShiftLibrary
Library             ../../../../libs/Helpers.py
Resource            ../../../Resources/RHOSi.resource
Resource            ../../../Resources/OCP.resource
Resource            ../../../Resources/Page/OCPDashboard/OCPDashboard.resource
Resource            ../../../Resources/Page/ODH/JupyterHub/HighAvailability.robot
Resource            ../../../Resources/Page/ODH/Prometheus/Prometheus.robot
Resource            ../../../Resources/ODS.robot
Resource            ../../../Resources/Page/ODH/Grafana/Grafana.resource
Resource            ../../../Resources/Page/HybridCloudConsole/HCCLogin.robot
Resource            ../../../Resources/Common.robot
Suite Setup         RHOSi Setup
Suite Teardown      RHOSi Teardown

*** Test Cases ***

Verify Dashbord has no message with NO Component Found
    [Tags]  Sanity
    ...     Tier1
    ...     ODS-1493
    [Documentation]   Verify "NO Component Found" message dosen't display
    ...     on Rhods Dashbord page with bad subscription present in openshift
    [Setup]   Test Setup For Rhods Dashboard
    Oc Apply  kind=Subscription  src=tests/Tests/100__deploy/100__installation/bad_subscription.yaml
    Delete Dashboard Pods And Wait Them To Be Back
    Reload Page
    Menu.Navigate To Page    Applications    Explore
    Sleep    10s
    Page Should Not Contain    No Components Found
    Capture Page Screenshot
    [Teardown]  Close All Browsers

Verify Traefik Deployment
    [Documentation]  Verifies RHODS Traefik deployment
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-546
    ...       ODS-552
    @{traefik} =  OpenShiftCLI.Get  kind=Pod  namespace=redhat-ods-applications  label_selector=name = traefik-proxy
    ${containerNames} =  Create List  traefik-proxy  configmap-puller
    Verify Deployment  ${traefik}  3  2  ${containerNames}

Verify JH Deployment
    [Documentation]  Verifies RHODS JH deployment
    [Tags]    Sanity
    ...       ODS-546  ODS-294  ODS-1250  ODS-237
    @{JH} =  OpenShiftCLI.Get  kind=Pod  namespace=redhat-ods-applications  label_selector=deploymentconfig = jupyterhub
    ${containerNames} =  Create List  jupyterhub  jupyterhub-ha-sidecar
    Verify JupyterHub Deployment  ${JH}  3  2  ${containerNames}

Verify GPU Operator Deployment  # robocop: disable
    [Documentation]  Verifies Nvidia GPU Operator is correctly installed
    [Tags]  Sanity
    ...     Resources-GPU  # Not actually needed, but we first need to enable operator install by default
    ...     ODS-1157

    # Before GPU Node is added to the cluster
    # NS
    Verify Namespace Status  label=kubernetes.io/metadata.name=redhat-nvidia-gpu-addon
    # Node-Feature-Discovery Operator
    Verify Operator Status  label=operators.coreos.com/ose-nfd.redhat-nvidia-gpu-addon
    ...    operator_name=ose-nfd.*
    # GPU Operator
    Verify Operator Status  label=operators.coreos.com/gpu-operator-certified.redhat-nvidia-gpu-addon
    ...    operator_name=gpu-operator-certified.v*
    # nfd-controller-manager
    Verify Deployment Status  label=operators.coreos.com/ose-nfd.redhat-nvidia-gpu-addon
    ...    dname=nfd-controller-manager
    # nfd-master
    Verify DaemonSet Status  label=app=nfd-master  dsname=nfd-master
    # nfd-worker
    Verify DaemonSet Status  label=app=nfd-worker  dsname=nfd-worker

    # After GPU Node is added to the cluster
    Verify DaemonSet Status  label=app=gpu-feature-discovery  dsname=gpu-feature-discovery
    Verify DaemonSet Status  label=app=nvidia-container-toolkit-daemonset  dsname=nvidia-container-toolkit-daemonset
    Verify DaemonSet Status  label=app=nvidia-dcgm-exporter  dsname=nvidia-dcgm-exporter
    Verify DaemonSet Status  label=app=nvidia-dcgm  dsname=nvidia-dcgm
    Verify DaemonSet Status  label=app=nvidia-device-plugin-daemonset  dsname=nvidia-device-plugin-daemonset
    #app=nvidia-driver-daemonset-410.84.202205191234-0
    #Verify DaemonSet Status  label=app=nvidia-driver-daemonset-*  dsname=nvidia-driver-daemonset-*
    Verify DaemonSet Status  label=app=nvidia-node-status-exporter  dsname=nvidia-node-status-exporter
    Verify DaemonSet Status  label=app=nvidia-operator-validator  dsname=nvidia-operator-validator
    Verify CR Status  crd=NodeFeatureDiscovery  cr_name=ocp-gpu-addon

Verify That Prometheus Image Is A CPaaS Built Image
    [Documentation]    Verifies the images used for prometheus
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-734
    ${pod} =    Find First Pod By Name    namespace=redhat-ods-monitoring    pod_start_with=prometheus-
    Verify Container Image    redhat-ods-monitoring    ${pod}    prometheus
    ...    "registry.redhat.io/openshift4/ose-prometheus"
    Verify Container Image    redhat-ods-monitoring    ${pod}    oauth-proxy
    ...    "registry.redhat.io/openshift4/ose-oauth-proxy:v4.8"

Verify That Grafana Image Is A Red Hat Built Image
    [Documentation]    Verifies the images used for grafana
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-736
    ${pod} =    Find First Pod By Name    namespace=redhat-ods-monitoring    pod_start_with=grafana-
    Verify Container Image    redhat-ods-monitoring    ${pod}    grafana
    ...    "registry.redhat.io/rhel8/grafana:7"
    Verify Container Image    redhat-ods-monitoring    ${pod}    auth-proxy
    ...    "registry.redhat.io/openshift4/ose-oauth-proxy:v4.8"

Verify That Blackbox-exporter Image Is A CPaaS Built Image
    [Documentation]    Verifies the image used for blackbox-exporter
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-735
    ${pod} =    Find First Pod By Name    namespace=redhat-ods-monitoring    pod_start_with=blackbox-exporter-
    Verify Container Image    redhat-ods-monitoring    ${pod}    blackbox-exporter
    ...    "quay.io/integreatly/prometheus-blackbox-exporter:v0.19.0"

Verify That Alert Manager Image Is A CPaaS Built Image
    [Documentation]    Verifies the image used for alertmanager
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-733
    ${pod} =    Find First Pod By Name    namespace=redhat-ods-monitoring    pod_start_with=prometheus-
    Verify Container Image    redhat-ods-monitoring    ${pod}    alertmanager
    ...    "registry.redhat.io/openshift4/ose-prometheus-alertmanager"

Verify Oath-Proxy Image Is fetched From CPaaS
    [Tags]      Sanity
    ...         Tier1
    ...         ODS-666
    ${pod} =    Find First Pod By Name  namespace=redhat-ods-applications   pod_start_with=rhods-dashboard-
    Verify Container Image      redhat-ods-applications     ${pod}      oauth-proxy
    ...     "registry.redhat.io/openshift4/ose-oauth-proxy:v4.8"

Verify Pytorch And Tensorflow Can Be Spawned
    [Documentation]    Check Cuda builds are complete and  Verify Pytorch and Tensorflow can be spawned
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-480  ODS-481
    Wait Until All Builds Are Complete    namespace=redhat-ods-applications
    Verify Image Can Be Spawned    image=pytorch  size=Default
    Verify Image Can Be Spawned    image=tensorflow  size=Default

Verify That Blackbox-exporter Is Protected With Auth-proxy
    [Documentation]    Vrifies the blackbok-exporter inludes 2 containers one for application and second for oauth proxy
    [Tags]  Sanity
    ...     Tier1
    ...     ODS-1090
    Verify BlackboxExporter Includes Oauth Proxy
    Verify Authentication Is Required To Access BlackboxExporter

Verify That "Usage Data Collection" Is Enabled By Default
    [Documentation]    Verify that "Usage Data Collection" is enabled by default when installing ODS
    [Tags]    Tier1
    ...       Sanity
    ...       ODS-1234

    ${version_check} =    Is RHODS Version Greater Or Equal Than    1.8.0
    IF    ${version_check}==True
        ODS.Usage Data Collection Should Be Enabled
        ...    msg="Usage Data Collection" should be enabled by default after installing ODS
    ELSE
        ODS.Usage Data Collection Should Not Be Enabled
        ...    msg="Usage Data Collection" should not be enabled by default after installing ODS
    END

Verify Tracking Key Used For "Usage Data Collection"
    [Documentation]    Verify that "Usage Data Collection" is enabled by default when installing ODS
    [Tags]    Tier1
    ...       Sanity
    ...       ODS-1235

    ODS.Verify "Usage Data Collection" Key

Verify RHODS Release Version Number
    [Documentation]    Verify RHODS version matches x.y.z-build format
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-478   ODS-472
    ${version} =  Get RHODS Version
    Should Match Regexp    ${version}    ^[0-9]+\.[0-9]+\.[0-9]+\(-[0-9]+)*$

Verify Users Can Update Notification Email After Installing RHODS With The AddOn Flow
    [Documentation]    Verifies the Alert Notification email is updated in Addon-Managed-Odh-Parameters Secret and Alertmanager ConfigMap
    [Tags]    Tier2
    ...       ODS-673
    ...       Deployment-AddOnFlow
    ${email_to_change} =    Set Variable    dummyemail1@redhat.com
    ${cluster_name} =    Common.Get Cluster Name From Console URL
    ${current_email} =    Get Notification Email From Addon-Managed-Odh-Parameters Secret
    Update Notification Email Address    ${cluster_name}    ${email_to_change}
    Wait Until Notification Email From Addon-Managed-Odh-Parameters Contains  email=${email_to_change}
    Wait Until Notification Email In Alertmanager ConfigMap Is    ${email_to_change}
    [Teardown]    Update Notification Email Address    ${cluster_name}    ${current_email}

Verify JupyterHub Pod Logs Dont Have Errors About Distutil Library
    [Documentation]    Verifies that there are no errors related to DistUtil Library in Jupyterhub Pod logs
    [Tags]    Tier2
    ...       ODS-586
    Verify Errors In Jupyterhub Logs

Verify Grafana Is Connected To Prometheus Using TLS
    [Documentation]    Verifies Grafana is connected to Prometheus using TLS
    [Tags]    Tier2
    ...       ODS-963
    [Setup]  Set Library Search Order  Selenium Library
    Verify Grafana Datasources Have TLS Enabled
    Verify Grafana Can Obtain Data From Prometheus Datasource
    [Teardown]  Close Browser

Verify CPU And Memory Requests And Limits Are Defined For All Containers In All Pods In All ODS Projects
    [Documentation]    Verifies that CPU and Memory requests and limits are defined
    ...                for all containers in all pods for all ODS projects
    [Tags]    Sanity
    ...       Tier1
    ...       ProductBug
    ...       ODS-385
    ...       ODS-554
    ...       ODS-556
    ...       ODS-313
    Verify CPU And Memory Requests And Limits Are Defined For All Containers In All Pods In Project    redhat-ods-applications
    Verify CPU And Memory Requests And Limits Are Defined For All Containers In All Pods In Project    redhat-ods-monitoring
    Verify CPU And Memory Requests And Limits Are Defined For All Containers In All Pods In Project    redhat-ods-operator

Verify Monitoring Stack Is Reconciled Without Restarting The ODS Operator
    [Documentation]    Verify Monitoring Stack Is Reconciled Without Restarting The RHODS Operator
    [Tags]    Tier2
    ...       ODS-699
    ...       Execution-Time-Over-15m
    Replace "Prometheus" With "Grafana" In Rhods-Monitor-Federation
    Wait Until Operator Reverts "Grafana" To "Prometheus" In Rhods-Monitor-Federation

Verify RHODS Dashboard Explore And Enabled Page Has No Message With No Component Found
    [Tags]  Tier2
    ...     ODS-1556
    ...     ProductBug
    [Documentation]   Verify "NO Component Found" message dosen't display
    ...     on Rhods Dashbord page with data value empty for rhods-enabled-applications-config
    ...     configmap in openshift
    ...     ProductBug:RHODS-4308
    [Setup]   Test Setup For Rhods Dashboard
    Oc Patch    kind=ConfigMap      namespace=redhat-ods-applications    name=rhods-enabled-applications-config    src={"data":null}   #robocop: disable
    Delete Dashboard Pods And Wait Them To Be Back
    Reload Page
    Menu.Navigate To Page    Applications   Enabled
    Sleep    5s    msg=Wait for page to load
    Run Keyword And Continue On Failure   Page Should Not Contain    No Components Found
    Menu.Navigate To Page    Applications   Explore
    Sleep    5s    msg=Wait for page to load
    Run Keyword And Continue On Failure   Page Should Not Contain    No Components Found
    [Teardown]   Test Teardown For Configmap Changed On RHODS Dashboard


*** Keywords ***
Delete Dashboard Pods And Wait Them To Be Back
    [Documentation]    Delete Dashboard Pods And Wait Them To Be Back
    Oc Delete    kind=Pod     namespace=redhat-ods-applications    label_selector=app=rhods-dashboard
    OpenShiftLibrary.Wait For Pods Status    namespace=redhat-ods-applications  label_selector=app=rhods-dashboard  timeout=120

Test Setup For Rhods Dashboard
    [Documentation]    Test Setup for Rhods Dashboard
    Set Library Search Order    SeleniumLibrary
    Launch Dashboard  ocp_user_name=${TEST_USER.USERNAME}  ocp_user_pw=${TEST_USER.PASSWORD}  ocp_user_auth_type=${TEST_USER.AUTH_TYPE}
    ...               dashboard_url=${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  browser_options=${BROWSER.OPTIONS}

Test Teardown For Configmap Changed On RHODS Dashboard
    [Documentation]    Test Teardown for Configmap changes on Rhods Dashboard
    Oc Patch    kind=ConfigMap      namespace=redhat-ods-applications    name=rhods-enabled-applications-config    src={"data": {"jupyterhub": "true"}}   #robocop: disable
    Delete Dashboard Pods And Wait Them To Be Back
    Close All Browsers

Verify Authentication Is Required To Access BlackboxExporter
    [Documentation]    Verifies authentication is required to access blackbox exporter. To do so,
    ...                runs the curl command from the prometheus container trying to access a blacbox-exporter target.
    ...                The test fails if the response is not a prompt to log in with OpenShift

    @{links} =    Prometheus.Get Target Endpoints
    ...    target_name=user_facing_endpoints_status
    ...    pm_url=${RHODS_PROMETHEUS_URL}
    ...    pm_token=${RHODS_PROMETHEUS_TOKEN}
    ...    username=${OCP_ADMIN_USER.USERNAME}
    ...    password=${OCP_ADMIN_USER.PASSWORD}
    Length Should Be    ${links}    2
    ${pod_name} =    Find First Pod By Name    namespace=redhat-ods-monitoring    pod_start_with=prometheus-
    FOR    ${link}    IN    @{links}
        ${command} =    Set Variable    curl --silent --insecure ${link}
        ${output} =    Run Command In Container    namespace=redhat-ods-monitoring    pod_name=${pod_name}
        ...    command=${command}    container_name=prometheus
        Should Contain    ${output}    Log in with OpenShift
        ...    msg=Log in with OpenShift should be required to access blackbox-exporter
    END

Verify BlackboxExporter Includes Oauth Proxy
    [Documentation]     Verifies the blackbok-exporter inludes 2 containers one for
    ...                 application and second for oauth proxy
    ${pod} =    Find First Pod By Name    namespace=redhat-ods-monitoring    pod_start_with=blackbox-exporter-
    @{containers} =    Get Containers    pod_name=${pod}    namespace=redhat-ods-monitoring
    List Should Contain Value    ${containers}    oauth-proxy
    List Should Contain Value    ${containers}    blackbox-exporter

Verify Errors In Jupyterhub Logs
    [Documentation]    Verifies that there are no errors related to Distutil Library in Jupyterhub Pod Logs
    @{pods} =    Oc Get    kind=Pod    namespace=redhat-ods-applications  label_selector=app=jupyterhub
    FOR    ${pod}    IN    @{pods}
        ${logs} =    Oc Get Pod Logs    name=${pod['metadata']['name']}   namespace=redhat-ods-applications
        ...    container=${pod['spec']['containers'][0]['name']}
        Should Not Contain    ${logs}    ModuleNotFoundError: No module named 'distutils.util'
    END

Verify Grafana Datasources Have TLS Enabled
    [Documentation]    Verifies TLS Is Enabled in Grafana Datasources
    ${secret} =  Oc Get  kind=Secret  name=grafana-datasources  namespace=redhat-ods-monitoring
    ${secret} =  Evaluate  base64.b64decode("${secret[0]['data']['datasources.yaml']}").decode('utf-8')  modules=base64
    ${secret} =  Evaluate  json.loads('''${secret}''')  json
    Run Keyword If  'tlsSkipVerify' in ${secret['datasources'][0]['jsonData']}
    ...  Should Be Equal As Strings  ${secret['datasources'][0]['jsonData']['tlsSkipVerify']}  False

Verify Grafana Can Obtain Data From Prometheus Datasource
    [Documentation]   Verifies Grafana Can Obtain Data From Prometheus Datasource
    ${grafana_url} =  Get Grafana URL
    Launch Grafana    ocp_user_name=${OCP_ADMIN_USER.USERNAME}    ocp_user_pw=${OCP_ADMIN_USER.PASSWORD}    ocp_user_auth_type=${OCP_ADMIN_USER.AUTH_TYPE}    grafana_url=https://${grafana_url}   browser=${BROWSER.NAME}   browser_options=${BROWSER.OPTIONS}
    Select Explore
    Select Data Source  datasource_name=Monitoring
    Run Promql Query  query=traefik_backend_server_up
    Page Should Contain  text=Graph

Verify CPU And Memory Requests And Limits Are Defined For All Containers In All Pods in Project
    [Documentation]    Verifies that CPU and Memory requests and limits are defined
    ...                for all containers in all pods for the specified project
    ...    Args:
    ...        project: Project name
    ...    Returns:
    ...        None
    [Arguments]    ${project}
    ${project_pods_info}=    Fetch Project Pods Info    ${project}
    FOR    ${pod_info}    IN    @{project_pods_info}
        Verify CPU And Memory Requests And Limits Are Defined For Pod    ${pod_info}
        IF    "${project}" == "redhat-ods-applications"
            Run Keyword If    "cuda-s2i" in "${pod_info['metadata']['name']}"
            ...    Verify Requests Contains Expected Values  cpu=2  memory=4Gi  requests=${pod_info['spec']['containers'][0]['resources']['requests']}
            Run Keyword If    "minimal-gpu" in "${pod_info['metadata']['name']}" or "pytorch" in "${pod_info['metadata']['name']}" or "tensorflow" in "${pod_info['metadata']['name']}"
            ...    Verify Requests Contains Expected Values  cpu=4  memory=8Gi  requests=${pod_info['spec']['containers'][0]['resources']['requests']}
        END
    END

Wait Until Operator Reverts "Grafana" To "Prometheus" In Rhods-Monitor-Federation
    [Documentation]     Waits until rhods-operator reverts the configuration of rhods-monitor-federation,
    ...    verifiying it has the default value ("prometheus")
    Sleep    10m    msg=Waits until rhods-operator reverts the configuration of rhods-monitor-federation
    Wait Until Keyword Succeeds    15m    1m    Verify In Rhods-Monitor-Federation App Is    expected_app_name=prometheus

Verify In Rhods-Monitor-Federation App Is
    [Documentation]     Verifies in rhods-monitor-federation, app is showing ${expected_app_name}
    [Arguments]         ${expected_app_name}
    ${data} =    OpenShiftLibrary.Oc Get    kind=ServiceMonitor   namespace=redhat-ods-monitoring    field_selector=metadata.name==rhods-monitor-federation
    ${app_name}    Set Variable    ${data[0]['spec']['selector']['matchLabels']['app']}
    Should Be Equal    ${expected_app_name}    ${app_name}

Replace "Prometheus" With "Grafana" In Rhods-Monitor-Federation
    [Documentation]     Replace app to "Prometheus" with "Grafana" in Rhods-Monirot-Federation
    OpenShiftLibrary.Oc Patch    kind=ServiceMonitor
    ...                   src={"spec":{"selector":{"matchLabels": {"app":"grafana"}}}}
    ...                   name=rhods-monitor-federation   namespace=redhat-ods-monitoring  type=merge

Verify Requests Contains Expected Values
    [Documentation]     Verifies cpu and memory requests contain expected values
    [Arguments]   ${cpu}  ${memory}  ${requests}
    Should Be Equal As Strings    ${requests['cpu']}  ${cpu}
    Should Be Equal As Strings    ${requests['memory']}  ${memory}
