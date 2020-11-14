#/bin/bash


# Устанавливаем ZFS
yum install http://download.zfsonlinux.org/epel/zfs-release.el7_8.noarch.rpm
vi /etc/yum.repos.d/zfs.repo
yum install zfs

# перезагрузка виртуальной машины
reboot

# загрука драйвера ZFS

modprome zfs
lsmod | grep zfs

#######################################

Задание - 1

# Создание пула из двух дисков
zpool create pool /dev/sdb /dev/sdc
zpool list
zpool status -v
 pool: pool
 state: ONLINE
  scan: none requested
config:

	NAME        STATE     READ WRITE CKSUM
	pool        ONLINE       0     0     0
	  sdb       ONLINE       0     0     0
	  sdc       ONLINE       0     0     0

# Создание нескольких файловых систем     
zfs create pool/gzip
zfs create pool/gzip-1
zfs create pool/gzip-5
zfs create pool/gzip-9
zfs create pool/zle
zfs create pool/lzjb
zfs create pool/lz4

# Смотрим результат
zfs list
NAME          USED  AVAIL     REFER  MOUNTPOINT
pool          318K   320M     31.5K  /pool
pool/gzip      24K   320M       24K  /pool/gzip
pool/gzip-1    24K   320M       24K  /pool/gzip-1
pool/gzip-5    24K   320M       24K  /pool/gzip-5
pool/gzip-9    24K   320M       24K  /pool/gzip-9
pool/lz4       24K   320M       24K  /pool/lz4
pool/lzjb      24K   320M       24K  /pool/lzjb
pool/zle       24K   320M       24K  /pool/zle

# Создаем сжатие gzip,gzip-1,gzip-5,gzip-9,zle,lzjb,lz4
zfs set compression=gzip pool/gzip
zfs set compression=gzip-1 pool/gzip-1
zfs set compression=gzip-5 pool/gzip-5
zfs set compression=gzip-9 pool/gzip-9
zfs set compression=zle pool/zle
zfs set compression=lzjb pool/lzjb
zfs set compression=lz4 pool/lz4

# Смотрим на тип сжатия на файловы системах
zfs get compression pool/gzip
NAME       PROPERTY     VALUE     SOURCE
pool/gzip  compression  gzip      local

zfs get compression pool/gzip-1
NAME         PROPERTY     VALUE     SOURCE
pool/gzip-1  compression  gzip-1    local

 zfs get compression pool/gzip-5
NAME         PROPERTY     VALUE     SOURCE
pool/gzip-5  compression  gzip-5    local

zfs get compression pool/gzip-9
NAME         PROPERTY     VALUE     SOURCE
pool/gzip-9  compression  gzip-5    local

zfs get compression pool/zle
NAME      PROPERTY     VALUE     SOURCE
pool/zle  compression  zle       local

zfs get compression pool/lzjb
NAME       PROPERTY     VALUE     SOURCE
pool/lzjb  compression  lzjb      local

 zfs get compression pool/lz4
NAME      PROPERTY     VALUE     SOURCE
pool/lz4  compression  lz4       local


# Скачиваем файл для теста сжатия
curl -o war.txt "http://www.gutenberg.org/cache/epub/2600/pg2600.txt"

# Копируем файлы в соответствующеи директории, я еще добавил otus_task2.file
cp -rp ./{war.txt,otus_task2.file} /pool/gzip
cp -rp ./{war.txt,otus_task2.file}/pool/gzip-1
cp -rp ./{war.txt,otus_task2.file} /pool/gzip-5
cp -rp ./{war.txt,otus_task2.file} /pool/gzip-9
cp -rp ./{war.txt,otus_task2.file} /pool/zle/
cp -rp ./{war.txt,otus_task2.file} /pool/lzjb/
cp -rp ./{war.txt,otus_task2.file} /pool/lz4/


# Смотрим коофициент сжатия 
 zfs get compressratio /pool/gzip
NAME       PROPERTY       VALUE  SOURCE
pool/gzip  compressratio  1.10x  -

 zfs get compressratio /pool/gzip-1
NAME         PROPERTY       VALUE  SOURCE
pool/gzip-1  compressratio  1.09x  -

zfs get compressratio /pool/gzip-5
NAME         PROPERTY       VALUE  SOURCE
pool/gzip-5  compressratio  1.10x  -

zfs get compressratio /pool/gzip-9
NAME         PROPERTY       VALUE  SOURCE
pool/gzip-9  compressratio  1.10x  -

 zfs get compressratio /pool/lz4/
NAME      PROPERTY       VALUE  SOURCE
pool/lz4  compressratio  1.09x  -

 zfs get compressratio /pool/lzjb/
NAME       PROPERTY       VALUE  SOURCE
pool/lzjb  compressratio  1.08x  -

 zfs get compressratio /pool/zle/
NAME      PROPERTY       VALUE  SOURCE
pool/zle  compressratio  1.07x  -

# Вывод. В данном случаи коофициент сжатия наилучший gzip,gzip-5,gzip-9 = 1.10x, gzip-1,lz4 = 1.09x, lzjb = 1.08x, zle = 1.07x
НО, как я понял сжатие зависит от типа файлов и от значений block size, recordsize и т.д.

###########################
Задание 2 

# Скачал zpoolexport
# Выполняю импорт, надо указать ключ -d потому что импорт из директории 
zpool import -d  zpoolexport otus

# смотрми что получилось
root@otusc7 vagrant]# zpool status -v
  pool: otus
 state: ONLINE
  scan: none requested
config:

	NAME                                 STATE     READ WRITE CKSUM
	otus                                 ONLINE       0     0     0
	  mirror-0                           ONLINE       0     0     0
	    /home/vagrant/zpoolexport/filea  ONLINE       0     0     0
	    /home/vagrant/zpoolexport/fileb  ONLINE       0     0     0


# Тип нашего пула otus - mirror-0
zpool type -  mirror-0

# Остальные данный по заданию нашел вот так:
[root@otusc7 vagrant]# zfs get all otus | egrep "available|recordsize|compression|checksum"
otus  available             350M                   -
otus  recordsize            128K                   local
otus  checksum              sha256                 local
otus  compression           zle                    local


###########################
Задание 3

# делаю receive с файла otus_task2.file 
zfs receive otus/storage@task2  < otus_task2.file

# Смотрим результат, появились /otus/hometask2 и /otus/storage
zfs list
NAME             USED  AVAIL     REFER  MOUNTPOINT
otus            4.93M   347M       25K  /otus
otus/hometask2  1.88M   347M     1.88M  /otus/hometask2
otus/storage    2.83M   347M     2.83M  /otus/storage

# Поиск файла secret_message
find /otus/ -type f -name "secret_message"
/otus/storage/task1/file_mess/secret_message

# Смотрим содержимое и это "https://github.com/sindresorhus/awesome"
cat /otus/storage/task1/file_mess/secret_message
https://github.com/sindresorhus/awesome


