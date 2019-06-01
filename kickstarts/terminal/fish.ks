%packages
fish
%end

%post
#chsh -s /usr/bin/fish liveuser
#usermod --shell /bin/fish liveuser
%end
