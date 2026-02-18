{ username, ... }:
{
  home.file.".local/share/user-places.xbel".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE xbel>
    <xbel xmlns:bookmark="http://www.freedesktop.org/standards/desktop-bookmarks" xmlns:kdepriv="http://www.kde.org/kdepriv" xmlns:mime="http://www.freedesktop.org/standards/shared-mime-info">
     <info>
      <metadata owner="http://www.kde.org">
       <kde_places_version>4</kde_places_version>
       <GroupState-Places-IsHidden>false</GroupState-Places-IsHidden>
       <GroupState-Remote-IsHidden>false</GroupState-Remote-IsHidden>
       <GroupState-Devices-IsHidden>false</GroupState-Devices-IsHidden>
       <GroupState-RemovableDevices-IsHidden>false</GroupState-RemovableDevices-IsHidden>
       <GroupState-Tags-IsHidden>false</GroupState-Tags-IsHidden>
       <withRecentlyUsed>true</withRecentlyUsed>
       <GroupState-RecentlySaved-IsHidden>false</GroupState-RecentlySaved-IsHidden>
       <withBaloo>true</withBaloo>
       <GroupState-SearchFor-IsHidden>false</GroupState-SearchFor-IsHidden>
      </metadata>
     </info>
     <bookmark href="file:///home/${username}">
      <title>Home</title>
      <info>
       <metadata owner="http://freedesktop.org">
        <bookmark:icon name="user-home"/>
       </metadata>
       <metadata owner="http://www.kde.org">
        <ID>1771206237/0</ID>
        <isSystemItem>true</isSystemItem>
       </metadata>
      </info>
     </bookmark>
     <bookmark href="file:///home/${username}/Desktop">
      <title>Desktop</title>
      <info>
       <metadata owner="http://freedesktop.org">
        <bookmark:icon name="user-desktop"/>
       </metadata>
       <metadata owner="http://www.kde.org">
        <ID>1771206237/1</ID>
        <isSystemItem>true</isSystemItem>
       </metadata>
      </info>
     </bookmark>
     <bookmark href="file:///home/${username}/Downloads">
      <title>Downloads</title>
      <info>
       <metadata owner="http://freedesktop.org">
        <bookmark:icon name="folder-download"/>
       </metadata>
       <metadata owner="http://www.kde.org">
        <ID>1771441467/1</ID>
       </metadata>
      </info>
     </bookmark>
     <bookmark href="file:///home/${username}/Development">
      <title>Development</title>
      <info>
       <metadata owner="http://freedesktop.org">
        <bookmark:icon name="inode-directory"/>
       </metadata>
       <metadata owner="http://www.kde.org">
        <ID>1771441463/0</ID>
       </metadata>
      </info>
     </bookmark>
     <bookmark href="remote:/">
      <title>Network</title>
      <info>
       <metadata owner="http://freedesktop.org">
        <bookmark:icon name="folder-network"/>
       </metadata>
       <metadata owner="http://www.kde.org">
        <ID>1771206237/2</ID>
        <isSystemItem>true</isSystemItem>
       </metadata>
      </info>
     </bookmark>
     <bookmark href="trash:/">
      <title>Trash</title>
      <info>
       <metadata owner="http://freedesktop.org">
        <bookmark:icon name="user-trash"/>
       </metadata>
       <metadata owner="http://www.kde.org">
        <ID>1771206237/3</ID>
        <isSystemItem>true</isSystemItem>
       </metadata>
      </info>
     </bookmark>
     <bookmark href="recentlyused:/files">
      <title>Recent Files</title>
      <info>
       <metadata owner="http://freedesktop.org">
        <bookmark:icon name="document-open-recent"/>
       </metadata>
       <metadata owner="http://www.kde.org">
        <ID>1771206237/4</ID>
        <isSystemItem>true</isSystemItem>
       </metadata>
      </info>
     </bookmark>
     <bookmark href="recentlyused:/locations">
      <title>Recent Locations</title>
      <info>
       <metadata owner="http://freedesktop.org">
        <bookmark:icon name="folder-open-recent"/>
       </metadata>
       <metadata owner="http://www.kde.org">
        <ID>1771206237/5</ID>
        <isSystemItem>true</isSystemItem>
       </metadata>
      </info>
     </bookmark>
    </xbel>
  '';
}
