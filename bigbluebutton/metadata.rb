maintainer        "Javier Perez-Griffo"
maintainer_email  "javier@besol.es"
license           "Apache 2.0"
description       "Installs bigbluebutton"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version          "0.3.2"
recipe           "bigbluebutton", "Installs and configures bigbluebutton"
recipe		 "bigbluebutton::beta", "Installs and configures bigbluebutton beta"

%w(apt mysql).each do |recipe_dependency|
  depends recipe_dependency
end

%w{ ubuntu debian }.each do |os|
  supports os
end
