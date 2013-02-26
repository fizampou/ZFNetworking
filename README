ZFNetworking is a general use assets downloader.

> Supports
 
- JSON parsing
- Cancel operation
- Monitor changes on server
- Track errors (no internet connection, connection lost)
- Redownload files if/ when changed
- Schema of the JSON for faster implementation
- Orientations
- Background images set on external plist file
- Progress bar for tracking the download progress
- Error messages on the user interface
- Designed for the Apple iPad 
- Background app pause download and resume later on.

> Requirements

a publick link in JSON format with the files for download (urls) and their hashed volues.

- Example:

"products": [
    {
      "product_id": "1082",
      "name": "mpla mpla",
      "sort_order": 0,
      "brand": "mploum",
      "product_category_id": "1090",
      "location_ids": [
        "1078",
        "1078"
      ],
      "icon_url": "http://www.mplum.com.askmmaks.png",
      "icon_date": "Wed, 07 Nov 2012 14:03:52 GMT",
      "icon_hash": "045e9dce02310e91271ab8b8843695c3",
      "thumbnail_url": "http://www.mkasmksamkas.com/asjnsanjsanjasnj.jpg",
      "thumbnail_date": "Wed, 07 Nov 2012 14:04:27 GMT",
      "thumbnail_hash": "a42fa3745ce969a2d03d3d821b35042c"
    },
    {
      "product_id": "1170",
      "name": "System",
      "sort_order": 1,
      "brand": "system",
      "product_category_id": "1090",
      "location_ids": [
        "1078"
      ],
      "icon_url": "http://www.askmkmsamkas.com/system.png",
      "icon_date": "Wed, 07 Nov 2012 14:03:47 GMT",
    
    ............
    ............

- You have to set that publick link on the serverAndImagesData.plist file as a LINK value.
- You can also set ther the names on the background images for both orientations.
- You have make the shema.plist before using that class
    > IN ITEMS set the items names from your JSON that have files for download (on the above example you would set just products).
    > IN LINKS you have to name them with the JSON names (on the above example you should make a resources array with items item0-> icon_url and icon_hash, item1-> thumbnail_url and thumbnail_hash)

Thats all you need to kickstart your next app development. When a file is changed on the server the hash value will be changed on the JSON so on the next app lanch the old file will be erased and a new version will be downloaded automaticly. The rest of the files will remain intact. 



