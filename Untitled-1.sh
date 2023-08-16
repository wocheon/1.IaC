
--os chck 

cat /etc/*release* | grep ^ID= | sed 's/ID=//g' | sed 's/\"//g'

-- install rpm
[CentOS7]
yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel wget
[Ubuntu]
apt-get install -y openjdk-8-jdk wget 


wget https://dlcdn.apache.org/tomcat/tomcat-8/v8.5.91/bin/apache-tomcat-8.5.91.tar.gz
tar -zxvf apache-tomcat-8.5.91.tar.gz 
mv apache-tomcat-8.5.91/ tomcat; mv tomcat /usr/local/lib/


-- set env

cat << EOF >> /etc/profile

JAVA_HOME=$(readlink -f /usr/bin/java | sed 's/\/bin\/java//g')
JRE_HOME=$JAVA_HOME/jre

CATALINA_HOME=/usr/local/lib/tomcat
PATH=$PATH:$JAVA_HOME/bin:$JRE_HOME/bin:$CATALINA_HOME/bin
CLASSPATH=.:$JAVA_HOME/lib/tools.jar:$CATALINA_HOME/lib/jsp-api.jar:$CATALINA_HOME/lib/servlet-api.jar

export JAVA_HOME
export JRE_HOME
export CLASSPATH CATALINA_HOME

EOF
source /etc/profile


-- tomcat service
cat << EOF > /etc/systemd/system/tomcat.service
[Unit]
Description=tomcat
After=network.target syslog.target

[Service]
Type=forking
Environment=/usr/local/lib/tomcat
User=root
Group=root
ExecStart=/usr/local/lib/tomcat/bin/startup.sh
ExecStop=/usr/local/lib/tomcat/bin/shutdown.sh

[Install]
WantedBy=multi-user.target
EOF

-- start tomcat 
systemctl deamon-reload
systemctl enable tomcat --now