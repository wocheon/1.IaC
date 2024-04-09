# GCP To AWS 파일전송 

## 개요
- 목표
    - GCP 버킷에 있는 파일을 AWS 버킷까지 전송
- 필요 리소스 
    - GCP 
        - 버킷 

        - 버킷에 엑세스하여 파일 다운로드 가능한 GCP 계정 
    - AWS
        - EC2 
            - 외부 연결이 가능한 상태여야 하므로 Internet-Gateway 및 Security-Group 설정 필요             
        
        - 버킷 
        
## EC2 생성 및 SSH 연결 

1. VPC 및 서브넷 생성 

2. SG(Security-Group) 생성 
    - ssh, http, https 허용 (anywhere)

3. IG(Internet-Gateway) 및 라우팅 테이블 생성 
    - IG 생성 및 라우팅테이블 생성후 라우팅 편집 
     0.0.0.0/0 - IG ( 외부 접속을 위함 )

4. VM 생성 및 키 페어 생성
    - AMI : Amazone Linux 
    - 유형: t2.micro

5. 탄력적 IP(외부IP) 생성 하여 VM에 연결

6. 키 사용하여 SSH 접속 확인

## EC2 내에서 Google-Cloud-SDK를 통해 GCP 연동

### Google-Cloud-SDK 설치 
- 참고 
    - https://cloud.google.com/sdk/docs/install-sdk?hl=ko

```bash
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-470.0.0-linux-x86_64.tar.gz

tar -xf google-cloud-cli-470.0.0-linux-x86_64.tar.gz

./google-cloud-sdk/install.sh
# 전부 엔터로 진행

Welcome to the Google Cloud CLI!
WARNING: You appear to be running this script as root. This may cause
the installation to be inaccessible to users other than the root user.

To help improve the quality of this product, we collect anonymized usage data
and anonymized stacktraces when crashes are encountered; additional information
is available at <https://cloud.google.com/sdk/usage-statistics>. This data is
handled in accordance with our privacy policy
<https://cloud.google.com/terms/cloud-privacy-notice>. You may choose to opt in this
collection now (by choosing 'Y' at the below prompt), or at any time in the
future by running the following command:

    gcloud config set disable_usage_reporting false

Do you want to help improve the Google Cloud CLI (y/N)?  y


Your current Google Cloud CLI version is: 470.0.0
The latest available version is: 471.0.0

┌────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                     Components                                                     │
├──────────────────┬──────────────────────────────────────────────────────┬──────────────────────────────┬───────────┤
│      Status      │                         Name                         │              ID              │    Size   │
├──────────────────┼──────────────────────────────────────────────────────┼──────────────────────────────┼───────────┤
│ Update Available │ BigQuery Command Line Tool                           │ bq                           │   1.7 MiB │
│ Update Available │ Google Cloud CLI Core Libraries                      │ core                         │  18.3 MiB │
│ Not Installed    │ App Engine Go Extensions                             │ app-engine-go                │   4.7 MiB │
│ Not Installed    │ Appctl                                               │ appctl                       │  21.0 MiB │
│ Not Installed    │ Artifact Registry Go Module Package Helper           │ package-go-module            │   < 1 MiB │
│ Not Installed    │ Cloud Bigtable Command Line Tool                     │ cbt                          │  17.3 MiB │
│ Not Installed    │ Cloud Bigtable Emulator                              │ bigtable                     │   7.3 MiB │
│ Not Installed    │ Cloud Datastore Emulator                             │ cloud-datastore-emulator     │  36.2 MiB │
│ Not Installed    │ Cloud Firestore Emulator                             │ cloud-firestore-emulator     │  44.5 MiB │
│ Not Installed    │ Cloud Pub/Sub Emulator                               │ pubsub-emulator              │  63.3 MiB │
│ Not Installed    │ Cloud Run Proxy                                      │ cloud-run-proxy              │  13.3 MiB │
│ Not Installed    │ Cloud SQL Proxy                                      │ cloud_sql_proxy              │   7.8 MiB │
│ Not Installed    │ Cloud Spanner Emulator                               │ cloud-spanner-emulator       │  36.2 MiB │
│ Not Installed    │ Cloud Spanner Migration Tool                         │ harbourbridge                │  20.9 MiB │
│ Not Installed    │ Google Container Registry's Docker credential helper │ docker-credential-gcr        │   1.8 MiB │
│ Not Installed    │ Kustomize                                            │ kustomize                    │   4.3 MiB │
│ Not Installed    │ Log Streaming                                        │ log-streaming                │  13.9 MiB │
│ Not Installed    │ Minikube                                             │ minikube                     │  35.4 MiB │
│ Not Installed    │ Nomos CLI                                            │ nomos                        │  28.7 MiB │
│ Not Installed    │ On-Demand Scanning API extraction helper             │ local-extract                │  14.4 MiB │
│ Not Installed    │ Skaffold                                             │ skaffold                     │  23.4 MiB │
│ Not Installed    │ Spanner migration tool                               │ spanner-migration-tool       │  23.5 MiB │
│ Not Installed    │ Terraform Tools                                      │ terraform-tools              │  66.1 MiB │
│ Not Installed    │ anthos-auth                                          │ anthos-auth                  │  21.8 MiB │
│ Not Installed    │ config-connector                                     │ config-connector             │  56.7 MiB │
│ Not Installed    │ enterprise-certificate-proxy                         │ enterprise-certificate-proxy │   8.6 MiB │
│ Not Installed    │ gcloud Alpha Commands                                │ alpha                        │   < 1 MiB │
│ Not Installed    │ gcloud Beta Commands                                 │ beta                         │   < 1 MiB │
│ Not Installed    │ gcloud app Java Extensions                           │ app-engine-java              │ 126.2 MiB │
│ Not Installed    │ gcloud app Python Extensions                         │ app-engine-python            │   5.0 MiB │
│ Not Installed    │ gcloud app Python Extensions (Extra Libraries)       │ app-engine-python-extras     │   < 1 MiB │
│ Not Installed    │ gke-gcloud-auth-plugin                               │ gke-gcloud-auth-plugin       │   7.9 MiB │
│ Not Installed    │ kpt                                                  │ kpt                          │  14.4 MiB │
│ Not Installed    │ kubectl                                              │ kubectl                      │   < 1 MiB │
│ Not Installed    │ kubectl-oidc                                         │ kubectl-oidc                 │  21.8 MiB │
│ Not Installed    │ pkg                                                  │ pkg                          │           │
│ Installed        │ Bundled Python 3.11                                  │ bundled-python3-unix         │  74.9 MiB │
│ Installed        │ Cloud Storage Command Line Tool                      │ gsutil                       │  11.3 MiB │
│ Installed        │ Google Cloud CRC32C Hash Tool                        │ gcloud-crc32c                │   1.2 MiB │
└──────────────────┴──────────────────────────────────────────────────────┴──────────────────────────────┴───────────┘
To install or remove components at your current SDK version [470.0.0], run:
  $ gcloud components install COMPONENT_ID
  $ gcloud components remove COMPONENT_ID

To update your SDK installation to the latest version [471.0.0], run:
  $ gcloud components update


Modify profile to update your $PATH and enable shell command completion?

Do you want to continue (Y/n)?  y

The Google Cloud SDK installer will now prompt you to update an rc file to bring the Google Cloud CLIs into your environment.

Enter a path to an rc file to update, or leave blank to use [/root/.bashrc]:
No changes necessary for [/root/.bashrc].

For more information on how to get started, please visit:
  https://cloud.google.com/sdk/docs/quickstarts

```
- 설치 완료 후 재로그인 필요 

### GCP 연동 

```bash
gcloud init

Welcome! This command will take you through the configuration of gcloud.

Your current configuration has been set to: [default]

You can skip diagnostics next time by using the following flag:
  gcloud init --skip-diagnostics

Network diagnostic detects and fixes local network connection issues.
Checking network connection...done.
Reachability Check passed.
Network diagnostic passed (1/1 checks passed).

You must log in to continue. Would you like to log in (Y/n)?  Y

Go to the following link in your browser:
# 아래 주소를 복사해서 웹브라우저로 열기
# GCP 권한이 있는 google 계정으로 로그인

    https://accounts.google.com/o/oauth2/auth?response_type=code&client_id=32555940559.apps.googleusercontent.com&redirect_uri=https%3A%2F%2Fsdk.cloud.google.com%2Fauthcode.html&scope=openid+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuserinfo.email+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcloud-platform+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fappengine.admin+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fsqlservice.login+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcompute+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Faccounts.reauth&state=9jTguSLyQddNUZDzpbKXE3ThFbih4z&prompt=consent&token_usage=remote&access_type=offline&code_challenge=-Ujw3qCKNkjkwa5oVtse4rfyXzioQJtxRmvYNs_9UB4&code_challenge_method=S256

# 로그인 후에 나오는 코드값을 복사 붙여넣기
Enter authorization code: **************


Updates are available for some Google Cloud CLI components.  To install them,
please run:
  $ gcloud components update

You are logged in as: [wocheon07@gmail.com].
# 활성화할 GCP 프로젝트 선택
Pick cloud project to use:
 [1] gcp-in-ca
 [2] Enter a project ID
 [3] Create a new project
Please enter numeric choice or text value (must exactly match list item):  1

Your current project has been set to: [gcp-in-ca].

Your project default Compute Engine zone has been set to [asia-northeast3-c].
You can change it by running [gcloud config set compute/zone NAME].

Your project default Compute Engine region has been set to [asia-northeast3].
You can change it by running [gcloud config set compute/region NAME].

Your Google Cloud SDK is configured and ready to use!
```

- GCP 버킷 목록 확인
```bash
$ gsutil ls
gs://asia-northeast3.deploy-artifacts.gcp-in-ca.appspot.com/
gs://cloud_sql_general_log_gcp_in_ca/
gs://gcp-in-ca-test-bucket-wocheon07/

$ gsutil ls gs://gcp-in-ca-test-bucket-wocheon07/
gs://gcp-in-ca-test-bucket-wocheon07/autopush.sh
gs://gcp-in-ca-test-bucket-wocheon07/filestore.yaml
gs://gcp-in-ca-test-bucket-wocheon07/startup_test.sh
gs://gcp-in-ca-test-bucket-wocheon07/var_test.yml
gs://gcp-in-ca-test-bucket-wocheon07/vm_info.txt
gs://gcp-in-ca-test-bucket-wocheon07/backup/
```

- 파일 다운로드 진행 

```bash
# 필요한경우 -m 옵션을 사용하면 병렬 다운로드 가능 
# 다만 VM에 부하가 꽤 크므로 주의
$ gsutil gs://gcp-in-ca-test-bucket-wocheon07/vm_info.txt .

Copying gs://gcp-in-ca-test-bucket-wocheon07/vm_info.txt...
/ [1 files][   30.0 B/   30.0 B]
Operation completed over 1 objects/30.0 B.

$ ll vm_info.txt
-rw-r--r--. 1 root root 30 Apr  9 06:17 vm_info.txt
```


### AWS CLI 연동 
- IAM > 사용자 > 엑세스키 생성 
    - 사용사례 : Command Line Interface(CLI)
    - 생성된 엑세스키는 csv파일등으로 저장해둘것

- 해당 엑세스키를 통해 aws CLI 연동을 진행 

```
aws configure
```

- MFA를 사용하는 경우 다음과 같이 사용 
```bash
[root@ip-192-168-1-144 .aws]# aws sts get-session-token --serial-number arn:aws:iam::******:mfa/ciw0707-s23 --token-code ******
{
    "Credentials": {
        "AccessKeyId": "********",
        "SecretAccessKey": "********",
        "SessionToken": "********",
        "Expiration": "2024-04-09T19:18:18+00:00"
    }
}

#export AWS_ACCESS_KEY_ID=엑세스키ID
#export AWS_SECRET_ACCESS_KEY=비밀엑세스키
#export AWS_SESSION_TOKEN=세션토큰

[root@ip-192-168-1-144 .aws]# export AWS_ACCESS_KEY_ID=********
export AWS_SECRET_ACCESS_KEY=********
export AWS_SESSION_TOKEN=********

```


### AWS 버킷에 파일 업로드
```
aws s3 ls
2024-04-09 06:39:08 an2-ciw-bucket

aws s3 cp vm_info.txt s3://an2-ciw-bucket
```
