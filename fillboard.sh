export LD_LIBRARY_PATH=/usr/local/boost_1_47_0/stage/lib

# Default values for variables
NuGames="100"
Size="13"
Time="1s"
Verbose=""
Config="/home/colblitz/Private/uap-mcts/config"
Results="/home/colblitz/Private/uap-mcts/results"
BPlayer="fuego"
WPlayer="fuego"
NewNum="0000"

# Command line arguments
if [ $# -eq 0 ]; then
  NuGames="10"
else
  NuGames="$1"
fi

# Set players
BPlayer="fuego --config $Config/test04.cfg"
WPlayer="fuego"

function setPlayers() {
  BPlayer="fuego --config $Config/$1.cfg"
  WPlayer="fuego --config $Config/$2.cfg"
}

# name, number_playouts, fillboard
function writeToConfig() {
  if [ $# -eq 3 ]; then
    echo "uct_param_search number_playouts $2" > $Config/$1.cfg
    echo "uct_param_policy fillboard_tries $3" >> $Config/$1.cfg
  else
    echo "uct_param_search number_playouts 1" > $Config/$1.cfg
    echo "uct_param_policy fillboard_tries 0" >> $Config/$1.cfg
  fi
}


function getNewNum() {
  if [ "$(ls -A $Results)" ]; then
    NewNum=
    for f in /home/colblitz/Private/uap-mcts/results/*.dat
    do
      if [ -z "$NewNum" ]
      then
        NewNum=$f
      elif [ "$f" -nt "$NewNum" ]
      then
        NewNum=$f
      fi
    done
    NewNum=$(basename "$NewNum")
    NewNum="${NewNum%.*}"
    NewNum=$((10#$NewNum+1))
    NewNum=`printf "%04d" $NewNum`
  else
    NewNum="0000"
  fi
}

# black number_playouts, white number_playouts, white fillboard
function runGames() {
  writeToConfig black $1 0
  writeToConfig white $2 $3
  setPlayers black white
  #getNewNum

  SGFDir="$Results/fillboardnew-[$Size][$Time][$1-0][$2-$3]"
  echo "Results file = $SGFDir"
  echo "Running $NuGames $Size x $Size games with time $Time"
  time1=$(date +%s.%N)
  time gogui-twogtp -black "$BPlayer" -white "$WPlayer" -alternate -games $NuGames -sgffile $SGFDir -size $Size -komi 7.5 -auto -time $Time $Verbose
  time2=$(date +%s.%N)

  echo ""
  echo "  Elapsed:  $(echo "$time2 - $time1"|bc )"
  totalTime=`echo "$time2-$time1"|bc`
  timePerGame=`echo "scale=9; $totalTime/$NuGames"|bc`
  echo "Time/Game:  $timePerGame"
  gogui-twogtp -analyze $SGFDir.dat
  mv $Results/*.sgf $Results/sgf/
  mv $Results/*.html $Results/html/
  mv $Results/*.summary.dat $Results/summary/
}

NuGames="200"
sizes=( 13 19 )
times=( 1s 5s )
fillboard=( 2 5 10 )
playouts=( 1 2 5 )

for s in "${sizes[@]}"
do
  for t in "${times[@]}"
  do
    for fill in "${fillboard[@]}"
    do
      for p in "${playouts[@]}"
      do
        Size=$s
        Time=$t
        runGames $p $p $fill
      done
    done
  done
done
