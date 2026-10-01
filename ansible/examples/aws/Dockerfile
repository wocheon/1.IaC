FROM centos
RUN yum -y install httpd
EXPOSE 80
ADD ./index.html /var/www/html/index.html
ENTRYPOINT /usr/sbin/httpd -D FOREGROUND
