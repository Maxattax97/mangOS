%packages
fish
%end

%post
sed -i -- 's/bash/zsh/g' /etc/default/useradd
sed -i -- 's/bash/zsh/g' /etc/adduser.conf
sed -i -- 's/bash/zsh/g' /etc/passwd
%end
