# Configuration Guide

This guide takes you through configuring the workshop environment step by step: the Central Server, the Security Servers `ss1` and `ss2`, a test service on `ss1`, and a test request from `ss2`. When you finish, the environment matches the setup described in the [README](../README.md#members-and-subsystems).

The steps follow the NIIS Knowledge Base article [How to Configure Central Server (version >= 7.3.0)](https://nordic-institute.atlassian.net/wiki/spaces/XRDKB/pages/215875585/How+to+Configure+Central+Server+version+7.3.0). In this environment, certificates are issued with ACME and management requests are approved automatically, so some steps differ from the article.

## Before You Begin

1. Download the required container images from the repository root:

   ```bash
   docker compose pull
   ```

2. Start the environment:

   ```bash
   docker compose up -d
   ```

3. Follow the logs and wait until all containers have started:

   ```bash
   docker compose logs -f
   ```

4. Copy the CA, OCSP responder and TSA certificates to `certs/`:

   ```bash
   scripts/export-ca-certs.sh
   ```

   The script writes `certs/ca.pem`, `certs/ocsp.pem` and `certs/tsa.pem`. You upload them to the Central Server in sections [1.3](#13-add-the-certification-service) and [1.4](#14-add-the-timestamping-service).

Use these values throughout the guide:

| Setting                                   | Value                    |
|-------------------------------------------|--------------------------|
| Instance identifier                       | `TEST`                   |
| Central Server address                    | `cs`                     |
| PIN (Central Server and Security Servers) | `123456xrd!`             |
| User interface credentials                | `xrd` / `secret`         |
| Central Server UI                         | <https://localhost:4000> |
| Security Server `ss1` UI                  | <https://localhost:1000> |
| Security Server `ss2` UI                  | <https://localhost:2000> |

> [!WARNING]
> Do not use several user interfaces in the same browser at the same time, because their sessions conflict. Use separate browsers or private windows instead.

## 1. Central Server

### 1.1 Log In and Initialize

1. Open <https://localhost:4000> and accept the self-signed certificate.
2. Log in with `xrd` / `secret`. If the services are still starting, an error is shown. Wait a moment and try again.
3. Enter the initial configuration:
   * **Instance Identifier**: `TEST`
   * **Central Server Address**: `cs`
   * **PIN** and **Repeat PIN**: `123456xrd!`
4. Press **Submit**.

Error messages about missing configuration appear afterwards. They are expected and disappear as you complete the following steps.

### 1.2 Add the Member Classes

1. Go to **Settings → System Settings → Member Classes** and press **Add**.
2. Enter code `COM` and description `Companies`, and save.
3. Repeat for code `GOV` with description `Government`.

### 1.3 Add the Certification Service

1. Go to **Trust Services → Certification Services** and press **Add certification service**.
2. Select `certs/ca.pem` and press **Upload**.
3. Fill in the certification service settings:
   * **Certificate Profile Info**: `ee.ria.xroad.common.certificateprofile.impl.BasicACMECertificateProfileInfoProvider`
   * **This CA can be used for ACME**: select.
   * **ACME server directory URL**: `http://ca:8887`
   * **ACME server IP address(es)**: leave empty.
   * **Authentication certificate profile id**: leave empty.
   * **Signing certificate profile id**: leave empty.
4. Press **Save**.

The certification service appears as `Test CA`, the name taken from the CA certificate, and is shown as ACME-capable. The profile ids stay empty because the test CA selects the certificate profile from the EAB key id that the Security Server sends (see [About ACME in This Environment](#about-acme-in-this-environment)).

Add the OCSP responder:

1. Open `Test CA` and go to **OCSP Responders**.
2. Press **Add**.
3. Enter the URL `http://ca:8888` and upload `certs/ocsp.pem`.
4. Select **Free**.
5. Press **Save**.

### 1.4 Add the Timestamping Service

1. Go to **Trust Services → Timestamping Services** and press **Add timestamping service**.
2. Enter the URL `http://ca:8899` and upload `certs/tsa.pem`.
3. Select **Free**.
4. Press **Add**.

The timestamping service appears as `Test TSA`.

### 1.5 Add the Members

1. Go to **Members** and press **Add member**.
2. Enter:
   * **Member name**: `Operator`
   * **Member class**: `GOV`
   * **Member code**: `1234`
3. Press **OK**.
4. Open `Operator`, go to **Subsystems** and press **Add new subsystem**.
5. Enter the subsystem code `MANAGEMENT`, subsystem name `Management` and press **Add**.
6. Add a second member with name `Organisation 1`, class `COM` and code `4321`.

Do not add `TestService` or `TestClient` here. You add them on the Security Servers, and the Central Server creates them when their client registration requests are approved.

### 1.6 Set the Management Services Provider

1. Go to **Settings → System Settings → Management Services**.
2. Next to **Service Provider Identifier**, press **Edit**.
3. Select subsystem `MANAGEMENT` of `Operator` (`TEST:GOV:1234:MANAGEMENT`) and press **Select**.

### 1.7 Add the Signing Keys

1. Go to **Global Configuration → Internal Configuration → Signing Keys**.
2. Press **Log in** and enter the PIN `123456xrd!`.
3. Press **Add key**, enter a friendly name such as `internal signing key`, and press **Add**.
4. Go to **Global Configuration → External Configuration → Signing Keys**.
5. Press **Add key**, enter a friendly name such as `external signing key`, and press **Add**.

After a while the global configuration is generated and the error messages disappear.

## 2. Security Server `ss1`

`ss1` is owned by `Operator` (`TEST:GOV:1234`). It hosts the management services and the test service.

### About ACME in This Environment

> [!NOTE]
> The Security Servers get their authentication and signing certificates from the test CA with ACME. You do not download CSRs or sign them manually, and the ACME client is already configured:
>
> * `acme.yml` holds the external account binding (EAB) credentials for CA `Test CA`, for the owner member only: `TEST:GOV:1234` on `ss1` and `TEST:COM:4321` on `ss2`. There are separate credentials for authentication and signing certificates, so the test CA issues the right certificate type.
> * `mail.yml` holds the member contact email that is used for the ACME account.
> * `local.ini` enables the ACME HTTP challenge port and automatic activation of ACME authentication and signing certificates. The CA validates the challenge by connecting to the Security Server over HTTP on port 80 inside `xroad-network`.
>
> Because EAB credentials exist only for the owner members, ACME orders work only for certificates of those members.

### 2.1 Initial Configuration

1. On the Central Server, go to **Global Configuration → Internal Configuration → Anchor** and press **Download**.
2. Open <https://localhost:1000>, accept the self-signed certificate and log in with `xrd` / `secret`.
3. Upload the configuration anchor, check that the hash matches the one shown on the Central Server, and press **Confirm**. Press **Continue**.
4. Enter the owner member and press **Continue**:
   * **Member class**: `GOV`
   * **Member code**: `1234` (the member name `Operator` is filled in automatically)
   * **Security Server code**: `ss1`
5. Enter the token PIN `123456xrd!` in both PIN fields and press **Submit**.

### 2.2 Log In to the Software Token

The Sidecar container logs in to the software token automatically with the PIN in `XROAD_TOKEN_PIN`. This works only because you chose the same PIN, `123456xrd!`, in the previous step.

If the token is still shown as logged out, go to **Keys and Certificates → SIGN and AUTH Keys**, press **Log in** next to **TOKEN: SOFTTOKEN-0** and enter the PIN.

### 2.3 Add the Timestamping Service

1. Go to **Settings → System Parameters → Timestamping Services** and press **Add**.
2. Select `Test TSA` and press **Add**.

### 2.4 Order the Certificates with ACME

Order the authentication certificate:

1. Go to **Keys and Certificates → SIGN and AUTH Keys**, select **TOKEN: SOFTTOKEN-0** and press **Add key**.
2. Enter the label `auth` and press **Next**.
3. Select:
   * **Usage**: **AUTHENTICATION**
   * **Certification Service**: **Test CA**
   * **CSR Format**: **DER**
4. Press **Continue**.
5. Enter `ss1` in **Server DNS Name (CN)** and in **Subject Alternative Name (SAN)**.
6. Add your preferred two-letter country code in **Country Code (C)**, such as `FI`.
7. Keep the other fields as prefilled, such as **Organization Name (O)**.
8. The last step offers **Generate CSR**, which saves the CSR to a file, and the option to order the certificate from the ACME server and import the returned certificate to the token. Press **Order Certificate**.
9. When "Certificate successfully ordered" is shown, press **Done**.

Order the signing certificate:

1. Select **TOKEN: SOFTTOKEN-0** again and press **Add key**.
2. Enter the label `sign` and press **Next**.
3. Select:
   * **Usage**: **SIGNING**
   * **Client**: `TEST:GOV:1234`
   * **Certification Service**: **Test CA**
   * **CSR Format**: **DER**
4. Press **Continue**.
5. Enter `ss1` in **Subject Alternative Name (SAN)**.
6. Add your preferred two-letter country code in **Country Code (C)**, such as `FI`.
7. Keep the other fields as prefilled.
8. Press **Order Certificate**, then **Done**.

The signing certificate is activated automatically and its OCSP status becomes good. The authentication certificate is activated after you register it in the next step.

If you generated a CSR without ordering, the CSR row in the key list has an **Order Certificate** button that does the same.

The test CA issues ACME certificates that are valid for 30 days. The Security Server renews them automatically, as shown in the **Automatic Renewal** column of the key list.

> [!TIP]
> If ordering fails:
>
> * "Fetching ACME server metadata failed": check that the **ACME server directory URL** of `Test CA` on the Central Server is `http://ca:8887` and that the `ca` container is running.
> * HTTP challenge failure: the CA must reach the Security Server on port 80 inside `xroad-network`. `local.ini` enables the challenge port; check that it was copied, see [Configuration Files](../README.md#configuration-files).
> * "Creating Account on ACME server failed" with a hint to check the credentials in `acme.yml`: the EAB credentials or the CA name in `acme.yml` do not match. The CA name must be `Test CA`.
> * **Order Certificate** is disabled with "Selected Certification Authority requires external account binding for ACME, but the credentials are missing from the configuration.": there are no EAB credentials for the selected member. Order certificates only for the owner member.

### 2.5 Register the Authentication Certificate

1. In **Keys and Certificates → SIGN and AUTH Keys**, press **Register** next to the authentication certificate.
2. Enter the DNS name `ss1` and press **Add**.

The certificate status changes to registration in progress. The Central Server approves the request automatically, and the Security Server then activates the certificate automatically.

1. On the Central Server, go to **Management Requests** and clear **Show only pending requests** to see the processed request.
2. On `ss1`, go to **Clients** and wait until the owner `Operator` changes from REGISTRATION IN PROCESS to REGISTERED.

The change can take a minute: the Central Server regenerates the global configuration every 10 seconds, but the Security Server fetches it on its own interval.

If the request stays pending, open it in **Management Requests** on the Central Server, press **Approve** and confirm with **Yes**.

### 2.6 Add the MANAGEMENT Subsystem

1. On `ss1`, go to **Clients** and press **Add subsystem**.
2. Press **Select Subsystem**, select the `MANAGEMENT` row of `TEST:GOV:1234` and press **Add selected**.
3. Press **Add subsystem** and confirm the registration with **Yes**.

The registration request fails, because the management services are not configured yet. This is expected. Fix it on the Central Server:

1. Go to **Settings → System Settings → Management Services**.
2. Next to **Management Services' Security Server**, press **Edit**.
3. Select `ss1` and press **Select**. A success message is shown.

On `ss1`, wait in **Clients** until `MANAGEMENT` is REGISTERED.

### 2.7 Configure the Management Services

1. On the Central Server, go to **Settings → System Settings → Management Services** and copy the **WSDL Address** and the **Management Services Address**. They should be:
   * **WSDL Address**: `http://cs/managementservices.wsdl`
   * **Management Services Address**: `https://cs:4002/managementservice/manage/`
2. On `ss1`, go to **Clients**, open `MANAGEMENT` and go to the **Services** tab.
3. Press **Add WSDL**, paste the WSDL address and press **Add**.
4. Enable the WSDL with its toggle and expand it with **>**.
5. Click `authCertDeletion` and set:
   * **Service URL**: the management services address, `https://cs:4002/managementservice/manage/`
   * **Timeout**: keep the default.
   * **Verify TLS certificate**: unchecked.
   * **Apply to all in WSDL**: checked.
6. Press **Save** and close the dialog.
7. Go to the **Service clients** tab and press **Add subject**.
8. Select **Security server owners** and press **Next**.
9. Select all management services and press **Add selected**. The list may vary by version; in this version it is `addressChange`, `authCertDeletion`, `clientDeletion`, `clientDisable`, `clientEnable`, `clientReg`, `clientRename`, `maintenanceModeDisable`, `maintenanceModeEnable` and `ownerChange`.

You test the management services when you register the next subsystem, in section [3.6](#36-add-the-testclient-subsystem).

## 3. Security Server `ss2`

`ss2` is owned by `Organisation 1` (`TEST:COM:4321`). It hosts the service consumer. Complete section [2](#2-security-server-ss1) first, because registering subsystems on `ss2` uses the management services configured on `ss1`.

### 3.1 Initial Configuration

1. On the Central Server, go to **Global Configuration → Internal Configuration → Anchor** and press **Download**. You can reuse the anchor downloaded in [2.1](#21-initial-configuration).
2. Open <https://localhost:2000>, accept the self-signed certificate and log in with `xrd` / `secret`.
3. Upload the configuration anchor, check that the hash matches the one shown on the Central Server, and press **Confirm**. Press **Continue**.
4. Enter the owner member and press **Continue**:
   * **Member class**: `COM`
   * **Member code**: `4321` (the member name `Organisation 1` is filled in automatically)
   * **Security Server code**: `ss2`
5. Enter the token PIN `123456xrd!` in both PIN fields and press **Submit**.

### 3.2 Log In to the Software Token

The Sidecar container logs in to the software token automatically with the PIN in `XROAD_TOKEN_PIN`. This works only because you chose the same PIN, `123456xrd!`, in the previous step.

If the token is still shown as logged out, go to **Keys and Certificates → SIGN and AUTH Keys**, press **Log in** next to **TOKEN: SOFTTOKEN-0** and enter the PIN.

### 3.3 Add the Timestamping Service

1. Go to **Settings → System Parameters → Timestamping Services** and press **Add**.
2. Select `Test TSA` and press **Add**.

### 3.4 Order the Certificates with ACME

ACME is configured on `ss2` in the same way as on `ss1`, see [About ACME in This Environment](#about-acme-in-this-environment). The EAB credentials on `ss2` are for `TEST:COM:4321`.

Order the authentication certificate:

1. Go to **Keys and Certificates → SIGN and AUTH Keys**, select **TOKEN: SOFTTOKEN-0** and press **Add key**.
2. Enter the label `auth` and press **Next**.
3. Select:
   * **Usage**: **AUTHENTICATION**
   * **Certification Service**: **Test CA**
   * **CSR Format**: **DER**
4. Press **Continue**.
5. Enter `ss2` in **Server DNS Name (CN)** and in **Subject Alternative Name (SAN)**.
6. Add your preferred two-letter country code in **Country Code (C)**, such as `FI`.
7. Keep the other fields as prefilled, such as **Organization Name (O)**.
8. The last step offers **Generate CSR**, which saves the CSR to a file, and the option to order the certificate from the ACME server and import the returned certificate to the token. Press **Order Certificate**.
9. When "Certificate successfully ordered" is shown, press **Done**.

Order the signing certificate:

1. Select **TOKEN: SOFTTOKEN-0** again and press **Add key**.
2. Enter the label `sign` and press **Next**.
3. Select:
   * **Usage**: **SIGNING**
   * **Client**: `TEST:COM:4321`
   * **Certification Service**: **Test CA**
   * **CSR Format**: **DER**
4. Press **Continue**.
5. Enter `ss2` in **Subject Alternative Name (SAN)**.
6. Add your preferred two-letter country code in **Country Code (C)**, such as `FI`.
7. Keep the other fields as prefilled.
8. Press **Order Certificate**, then **Done**.

The signing certificate is activated automatically and its OCSP status becomes good. The authentication certificate is activated after you register it in the next step.

If ordering fails, see the troubleshooting tips at the end of [2.4](#24-order-the-certificates-with-acme).

### 3.5 Register the Authentication Certificate

1. In **Keys and Certificates → SIGN and AUTH Keys**, press **Register** next to the authentication certificate.
2. Enter the DNS name `ss2` and press **Add**.

The certificate status changes to registration in progress. The Central Server approves the request automatically, and the Security Server then activates the certificate automatically.

1. On the Central Server, go to **Management Requests** and clear **Show only pending requests** to see the processed request.
2. On `ss2`, go to **Clients** and wait until the owner `Organisation 1` changes from REGISTRATION IN PROCESS to REGISTERED.

The change can take a minute: the Central Server regenerates the global configuration every 10 seconds, but the Security Server fetches it on its own interval.

If the request stays pending, open it in **Management Requests** on the Central Server, press **Approve** and confirm with **Yes**.

### 3.6 Add the TestClient Subsystem

1. On `ss2`, go to **Clients** and press **Add subsystem**.
2. Select the member `TEST:COM:4321` and enter the subsystem code `TestClient`.
3. Register the subsystem and confirm with **Yes**.

The Central Server approves the request automatically and creates the subsystem. Wait until `TestClient` is REGISTERED. If the request stays pending, approve it in **Management Requests** on the Central Server.

Set the connection type to HTTP, because the example requests are sent over plain HTTP to port `8080` of `ss2`:

1. Open `TestClient` and go to the **Internal servers** tab.
2. Set **Connection type** to **HTTP**.

## 4. Service Provider on `ss1`

### 4.1 Add the TestService Subsystem

1. On `ss1`, go to **Clients** and press **Add subsystem**.
2. Select the member `TEST:GOV:1234` and enter the subsystem code `TestService`.
3. Register the subsystem and confirm with **Yes**.

Wait until `TestService` is REGISTERED. The request is approved automatically.

### 4.2 Add the SOAP Services

1. Open `TestService` and go to the **Services** tab.
2. Press **Add WSDL**, enter `http://is:8080/example-adapter/Endpoint?wsdl` and press **Add**.
3. Enable the WSDL with its toggle and expand it with **>**.
4. Click `getRandom.v1` and set:
   * **Service URL**: the management services address, `http://is:8080/example-adapter/Endpoint`
   * **Timeout**: keep the default.
   * **Verify TLS certificate**: unchecked.
   * **Apply to all in WSDL**: checked.
5. Press **Save** and close the dialog.

The WSDL adds the services `getRandom`, `helloService`, `listPeople` and `personDetails`, all version `v1`, with the service URL `http://is:8080/example-adapter/Endpoint`.

### 4.3 Grant Access Rights

`TestClient` must be registered ([3.6](#36-add-the-testclient-subsystem)) before you can find it here.

1. In `TestService`, go to the **Service clients** tab and press **Add subject**.
2. Search for `TestClient`, select `TEST:COM:4321:TestClient` and press **Next**.
3. Select all services and press **Add selected**.

### 4.4 Add a REST Service

This step needs internet access from `ss1`.

1. In `TestService`, go to the **Services** tab and press **Add REST**.
2. Select **OpenAPI 3 Description** and enter:
   * **URL**: `https://d14r9k0rinox9f.cloudfront.net/yaml/x-road-stats.yaml`
   * **Service Code**: `XRoadStatistics`
3. Press **Add**, enable the service with its toggle and expand it with **>**.
4. Click `XRoadStatistics` and set:
   * **Service URL**: keep the default.
   * **Timeout**: keep the default.
   * **Verify TLS certificate**: unchecked.
5. Press **Save** and press **Add subjects**.
6. Press **Search**.
7. Select **Test client** (`TEST:COM:4321:TestClient`) and press **Add selected**.
8. Click **Close**.

## 5. Test the Environment

Run the requests from the `requests` directory, see [Sending Requests](../README.md#sending-requests):

```bash
cd requests
```

List the services of `TestService`:

```bash
../scripts/send-request.sh -d @listMethods.xml --header "Content-Type: text/xml" -X POST http://ss2:8080
```

The response lists the services you added in [4.2](#42-add-the-soap-services).

Call `getRandom`:

```bash
../scripts/send-request.sh -d @getRandom.xml --header "Content-Type: text/xml" -X POST http://ss2:8080
```

The response contains a random number.

Call `helloService`:

```bash
../scripts/send-request.sh -d @helloService.xml --header "Content-Type: text/xml" -X POST http://ss2:8080
```

The response contains "Hello Test! Greetings from adapter server!".

### REST Service

These calls test the `XRoadStatistics` REST service from the optional step [4.4](#44-optional-add-a-rest-service). They don't use request files, so run them from the repository root:

```bash
cd ..
```

List the X-Road instances that the statistics API knows about:

```bash
scripts/send-request.sh -X GET -H 'X-Road-Client: TEST/COM/4321/TestClient' -i 'http://ss2:8080/r1/TEST/GOV/1234/TestService/XRoadStatistics/instances'
```

The response is `HTTP/1.1 200 OK` with a JSON list of instance identifiers.

Get the statistics of the instance `FI`:

```bash
scripts/send-request.sh -X GET -H 'X-Road-Client: TEST/COM/4321/TestClient' -i 'http://ss2:8080/r1/TEST/GOV/1234/TestService/XRoadStatistics/instances/FI'
```

The response is JSON with the member classes and member counts of the instance.

Get the OpenAPI description of the service with the X-Road metaservice `getOpenAPI`:

```bash
scripts/send-request.sh -X GET -H 'X-Road-Client: TEST/COM/4321/TestClient' -i 'http://ss2:8080/r1/TEST/GOV/1234/TestService/getOpenAPI?serviceCode=XRoadStatistics'
```

The response is the OpenAPI 3 description in YAML.

With `-i`, curl also prints the response headers. The `x-road-client` and `x-road-service` headers show the identifiers the request used.

If the response is an error about the client connection type, check that the connection type of `TestClient` is **HTTP** ([3.6](#36-add-the-testclient-subsystem)).

## 6. Cleanup

To stop the environment without removing the resources:

```bash
docker compose stop
```

To remove the containers and all volumes, including the CA and its keys:

```bash
docker compose down -v
```
