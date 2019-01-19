# SUserDefaults
##### Store data securely using SUserDefaults.
##### Even after application remove from device still data is present because of we store data in keychain.

# Getting Started
**String**
>**SUserDefaults.standard.set("string","key")**

**Float**
>**SUserDefaults.standard.set(123,"key")**

**Boolean**
>**SUserDefaults.standard.set(true,"key")**

**Image**
>**SUserDefaults.standard.set(UIImage("nameOfImage"),"key")**

All datatypes are store in SUserDefaults.
Use different key name insted of key parameters.
