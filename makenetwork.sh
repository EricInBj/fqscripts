cidr2mask ()
{
   # Number of args to shift, 255..255, first non-255 byte, zeroes
   set -- $(( 5 - ($1 / 8) )) 255 255 255 255 $(( (255 << (8 - ($1 % 8))) & 255 )) 0 0 0
   [ $1 -gt 1 ] && shift $1 || shift
   echo ${1-0}.${2-0}.${3-0}.${4-0}
}

generate_config() {
  local file=$2
  [ -z "$file" ] && file=/proc/self/fd/0
  while read x;do
    [ -z "$x" ] && continue
    local ip=${x%%/*}
    local mask=`cidr2mask ${x##*/}`
    echo "config route"
    echo -e "\toption interface '$1'"
    echo -e "\toption target '$ip'"
    echo -e "\toption netmask '$mask'"
  done < $file
}

mergeprefixes() {
  awk -F/ '{ printf("%s.%s\n", $1, lshift(1,32-$2)) }' \
  | awk -F. ' { printf("%.0f %d\n",lshift($1,24)+lshift($2,16)+lshift($3,8)+$4,$5) } ' \
  | sort -n | awk '
  BEGIN{curbeg=0;curlen=0;}
  {
    if($1<=curbeg+curlen){
      new_curlen=$1+$2-curbeg;
      if(new_curlen>curlen) curlen=new_curlen;
    }else{
      print_current();
      curbeg=$1;
      curlen=$2;
    }
  }
  END{
    print_current();
  }
  function print_current(){
    while(curlen>0){
      i=0;
      while(lshift(rshift(curbeg,i),i)==curbeg) i++;
      i=lshift(1,i-1);
      if(i>curlen){
        i=1;
        while(i<=curlen) i=lshift(i,1);
        i=rshift(i,1);
      }
      a=rshift(curbeg,24);
      b=rshift(and(curbeg,lshift(255,16)),16);
      c=rshift(and(curbeg,lshift(255,8)),8);
      d=and(curbeg,255);
      printf("%d.%d.%d.%d/%d\n",a,b,c,d,32-log(i)/log(2));
      curbeg+=i;
      curlen-=i;
    }
  }
  '
}

cd `dirname $0`
cat /etc/config/network.core
(
  for x in getprefixes.*.sh;do ./$x;done
)|mergeprefixes|generate_config $1 $2
