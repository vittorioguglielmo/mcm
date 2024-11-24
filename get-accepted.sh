#!/usr/bin/bash
log_path_today="/home/USERNAME"
log_path_archived="/home/USERNAME/archived_logs"
command="cat"

estrai() { 
while [[ $start -le $end ]]
do
        day=$(date -d $start +%Y-%m-%d)
	accepted=$($command $log_path/LOG_LOCAL_PREFIX.log$log_suffix |grep -i Accepted|grep "S"|wc -l)

if [ "$accepted" != "" ]; then
	#difference=$(($last-$first))
	COUNTER=$(expr $COUNTER + 1)
	#total=$(($total+$difference))
	total=$(($total+$accepted))
	#echo $day " accepted are "$difference
	echo $day " accepted are "$accepted
fi

        start=$(date -d"$start + 1 day" +"%Y%m%d")
	log_suffix="-"$start".gz"
done

if [ $media = 1 ]; then
	echo
	echo "Media :" $(($total/$COUNTER))
fi

}

if [ "$1" = "yesterday" ];then

	day=$(date -d"- 1 day" +"%Y%m%d")
	#log_suffix="-"$(date -d"- 1 day" +"%Y%m%d")".gz"
	#log_suffix="-"$(date  +"%Y%m%d")".gz"
	log_suffix="-"$day".gz"
	log_path=$log_path_archived
	command="zcat"
	start=$day
	end=$day
	media=0
        estrai
	exit 0
fi

if [ "$1" = "today" ];then
	day=$(date  +"%Y%m%d")
	log_path=$log_path_today
	command="cat"
	start=$day
        end=$day
        media=0
        estrai
        exit 0
fi	

echo -n "Inserisci data di partenza AAAA-MM-GG (esempio 2022-12-31) : "
read start
startdate=$(date -I -d "$start") || exit -1
echo -n "Inserisci data di fine AAAA-MM-GG (esempio 2023-12-31) : "
read end
enddate=$(date -I -d "$end") || exit -1
start=$(date -d $start +%Y%m%d)
end=$(date -d $end +%Y%m%d)
log_path=$log_path_archived
log_suffix="-"$start".gz"
command="zcat"
telegram=0
estrai
#
