Resume Template

yum install unzip wget httpd -y
git clone https://github.com/utrains/static-resume.git
rm -rf /var/www/html/*
cp -r static-resume/* /var/www/html/
systemctl start httpd
systemctl enable httpd


