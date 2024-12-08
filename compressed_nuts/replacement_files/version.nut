function GetVersion(){return 1551211
}
function GetReplayVersion(){return 1551210
}
this.current_version<-::manbow.GetPrivateProfileString("updater","version","0","config.ini").tointeger()
function GetUpdaterVersion(){return this.current_version
}
function GetVersionString(){return "Ver1.21b+squiroll v"+::setting.version+"."+::setting.revision
}
function GetVersionSignature(){return "1_21b+R"+::setting.version
}
::SetWindowText("Touhou Hyouibana ~ Antinomy of Common Flowers. "+this.GetVersionString())
