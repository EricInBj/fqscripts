cd `dirname $0`

prefixesfromasn() {
  curl -s https://stat.ripe.net/data/announced-prefixes/data.json?resource=$1 --insecure|awk -F\" '/\"prefix\": *\"[0-9.\/]+\"/{print $4}'
}

for x in `cat asn.txt|grep -v '^#'|grep -v '^$'`;do prefixesfromasn.sh $x;done