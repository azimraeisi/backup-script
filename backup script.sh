# !/bin/bash
date1=$(date '+%Y-%m-%d')
Host=`hostname`
DestIP=x.x.x.x
UserName=Azim
recievers=azim@raeisi.co
SenderAddress=BackupReport@raeisi.co

#start of taking backup from first directory
#to add new dir to taking backup please copy from start till end and modify only "-filename -SourceDir -DestDir"
filename=x_$date1.tgz
SourceDir=/app/cdr
DestDir=/data/app_cdr_bkp

SourceFiles=*
SourceAll=$SourceDir/$SourceFiles
FreeSpaceDir=`echo $SourceDir| awk -F '/' '{print "/" $2}'`

RequestSpace=`du -BG -bch --block-size=1G $SourceDir | grep total | awk '{print $1}' | cut -d'G' -f1 | awk -F '.' '{print $1}'`
FreeSpace=`df -BG |grep $FreeSpaceDir | awk '{ print $3 }' | cut -d'G' -f1 | awk -F '.' '{print $1}'`
DestFreeSpcae=`ssh $UserName@$DestIP df -BG /data | awk '{print $4}' | grep -Eo "[0-9]+" | awk -F '.' '{print $1}'`
if [[ $RequestSpace -lt $FreeSpace ]] ; then
    if [[ $RequestSpace -lt $DestFreeSpcae ]]; then
        tar -g $SourceDir/FullArchive.snar -cvzf  $SourceDir/$filename $SourceAll
        rsync -e "ssh -o StrictHostKeyChecking=no" $SourceDir/$filename $DestIP:$DestDir
    else
        echo "Backup $SourceAll failed, free space is not enough on destination server" | mailx -r $SenderAddress -s "Backup failed on $Host" $recievers
        
    fi
else
    echo "Backup $SourceAll failed, free space is not enough on source server" | mailx -r $SenderAddress -s "Backup failed on $Host" $recievers
    
fi

DestFilemd5=`ssh $UserName@$DestIP md5sum $DestDir/$filename | awk  '{print $1}'`
SourceFilemd5=`md5sum $SourceDir/$filename | awk  '{print $1}'`
if [ ! -z "$DestFilemd5" ] && [ ! -z "$SourceFilemd5" ]; then
    if [[ "$DestFilemd5" == "$SourceFilemd5" ]] ; then
            echo "Backup $SourceAll successful on $Host " | mailx -r $SenderAddress -s "Backup successful on $Host" $recievers
        else
            echo "Backup $SourceAll in source and destination are not same on $Host \n please check ASAP."| mailx -r $SenderAddress -s "Backup failed on $Host" $recievers
            
    fi
    else
    echo "Backup $SourceAll failed on $Host  please check ASAP."| mailx -r $SenderAddress -s "Backup failed on $Host" $recievers
    
fi
rm -rf $SourceDir/$filename
#end 