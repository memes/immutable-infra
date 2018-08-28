#!/bin/sh

# Install nginx
sudo apt-get install -y nginx

# Customise home page
sudo sh -c "cat > /var/www/html/index.html" <<EOF
<html>
  <head>
    <title>Hello from Terraform!</title>
  </head>
  <body>
    <h1>Hello from Terraform!</h1>
    <h2>${host}</h2>
  </body>
</html>
EOF

# Make sure nginx is enabled and running
sudo systemctl enable nginx
sudo systemctl restart nginx
