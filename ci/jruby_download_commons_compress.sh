VERSION=1.16.1
JAR_PATH=commons-compress-${VERSION}/commons-compress-${VERSION}.jar
URL=http://archive.apache.org/dist/commons/compress/binaries/commons-compress-${VERSION}-bin.tar.gz

if `ruby -v | grep -q jruby`; then
  mkdir java > /dev/null 2>&1
  curl $URL | tar -xz -C java $JAR_PATH
  export CLASSPATH=java/${JAR_PATH}
fi
