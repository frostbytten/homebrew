require 'formula'

class Php53osx <Formula
  url 'http://us.php.net/get/php-5.3.3.tar.bz2/from/www.php.net/mirror'
  version '5.3.3'
  homepage 'http://php.net'
  md5 '21ceeeb232813c10283a5ca1b4c87b48'

  # DEPENDENCIES
  if ARGV.include? '--default-osx'
    depends_on 'jpeg'
    depends_on 'libpng'
    depends_on 'libxml2'
    depends_on 'sqlite'
    depends_on 'pcre'
  else
    if (ARGV.include? '--with-mysql') && (!ARGV.include? '--with-native-mysql')
      puts "Requiring MySQL"
      depends_on 'mysql'
    end
    if ARGV.include? '--with-sqlite'
      depends_on 'sqlite'
    end
  end
  if ARGV.include? '--with-fpm'
    depends_on 'libevent'
  end

  def patches
    # Typical Mac OSX+PHP libiconv patch
    # Added the Mac OSX mysqli non-native bug fix
    DATA
  end
  
  def options
    [
      ['--default-osx',       "Build like the default OS X PHP install (minus ODBC, Phar)"],
      ['--with-mysql',        "Build with MySQL (PDO) support from homebrew"],
      ['--with-native-mysql', "Build with native MySQL drivers [supplied by --default-osx]"],
      ['--with-sqlite',       "Build with SQLite3 (PDO) support from homebrew"],
      ['--with-osx-sqlite',   "Build with SQLite3 (PDO) from OS X"],
      ['--with-fpm',          "Build with PHP-FPM"],
      ['--without-apache',    "Do not build with the Apache SAPI (use with --default-osx)"]
    ]
  end

  def caveats
    <<-END_CAVEATS
    This formula has installed libxml2 and libiconv to bypass some errors included
    within the default OS X libraries.
    
    If you would like to customize your php.ini please edit:
    #{HOMEBREW_PREFIX}/etc/php.ini
    
    If you used --with-fpm please edit:
    #{HOMEBREW_PREFIX}/etc/php-fpm.ini
    
    Switches:
    Pass --default-osx        to build like the default OS X install of PHP (including binding to default Apache install)
    Pass --with-mysql         to build with MySQL (PDO) support
    Pass --with-native-mysql  to build with native MySQL drivers [supplied by --default-osx]
    Pass --with-sqlite        to build with SQLite3 (PDO) support from homebrew
    Pass --with-osx-sqlite    to build with SQLite3 (PDO) from OS X
    Pass --with-fpm           to build with PHP-FPM
    Pass --without-apache     to NOT build the Apache SAPI (use with --default-osx to disable binding to default Apache install)
    END_CAVEATS
  end

  def skip_clean? path
    path == bin+'php'
  end

  def install
    configure_args = [
      "--prefix=#{prefix}",
      "--disable-debug",
      "--disable-dependency-tracking",
      "--with-config-file-path=#{prefix}/etc",
      "--sysconfdir=#{prefix}/etc",
      "--without-pear",
      "--enable-cgi",
      "--mandir=#{man}",
      "--with-iconv-dir=/usr"
    ]

    if (!ARGV.include? '--without-apache') && (ARGV.include? '--default-osx')
      puts "Building with Apache SAPI"
      configure_args.push("--with-apxs2=/usr/sbin/apxs", "--libexecdir=#{prefix}/libexec")
    end

    if (ARGV.include? '--default-osx') || (ARGV.include? '--with-mysql')
      puts "Building with MySQL (PDO) support"
      # Now for the DB stuff
      if (ARGV.include? '--with-mysql') && (!ARGV.include? '--with-native-mysql')
        configure_args.push("--with-mysql=#{HOMEBREW_PREFIX}/lib/mysql",
        "--with-mysqli=#{HOMEBREW_PREFIX}/bin/mysql_config",
        "--with-pdo-mysql=#{HOMEBREW_PREFIX}/bin/mysql_config")
      else
        puts "Using native MySQL drivers"
        configure_args.push("--with-mysql=mysqlnd",
        "--with-mysqli=mysqlnd",
        "--with-pdo-mysql=mysqlnd",
        "--with-mysql-sock=/tmp/mysql.sock")       
      end
    end

    if (ARGV.include? '--default-osx') || (ARGV.include? '--with-osx-sqlite')
      puts "Building with SQLite3 (PDO) support [OS X libraries]"
      configure_args.push("--with-pdo-sqlite=/usr")
    end
    
    if (ARGV.include? '--with-sqlite')
      puts "Building with SQLite3 (PDO support [homebrew libraries])"
      configure_args.push("--with-pdo-sqlite=#{HOMEBREW_PREFIX}")
    end

    if ARGV.include? '--default-osx'  
      # Now for the GD stuff
      configure_args.push("--with-gd",
      "--with-jpeg-dir=#{HOMEBREW_PREFIX}",
      "--with-png-dir=#{HOMEBREW_PREFIX}/Cellar/libpng/#{versions_of("libpng").first}",
      "--with-freetype-dir=/usr/X11",
      "--enable-gd-native-ttf")

      # Misc default stuff
      configure_args.push("--with-libxml-dir=#{HOMEBREW_PREFIX}",
      "--with-openssl=/usr",
      "--with-kerberos=/usr",
      "--with-ldap=/usr",
      "--with-ldap-sasl=/usr",
      "--with-pcre-regex",
      "--with-zlib=/usr",
      "--enable-bcmath",
      "--with-bz2",
      "--enable-calendar",
      "--with-curl=/usr",
      "--enable-exif",
      "--enable-ftp",
      "--enable-mbstring",
      "--enable-shmop",
      "--enable-soap",
      "--enable-sockets",
      "--enable-sysvmsg",
      "--enable-sysvsem",
      "--enable-sysvshm",
      "--with-xmlrpc",
      "--with-xsl",
      "--enable-zip",
      "--with-iodbc=/usr")
    end

    if ARGV.include? '--with-fpm'
      puts "Building PHP-FPM"
      configure_args.push("--with-libevent-dir=#{HOMEBREW_PREFIX}", 
      "--enable-fpm")
    end

    system "./configure", *configure_args


    #mkfile = File.open("Makefile")
    #newmk  = File.new("Makefile.fix", "w")
    #mkfile.each do |line|
    #    if /^EXTRA_LIBS =(.*)$/ =~ line
    #        newmk.print "EXTRA_LIBS =", $1, " -lresolv\n"
    #    elsif /^MH_BUNDLE_FLAGS =(.*)$/ =~ line
    #        newmk.print "MH_BUNDLE_FLAGS =", $1, " -lresolv\n"
    #    elsif /\$\(CC\) \$\(MH_BUNDLE_FLAGS\)/ =~ line
    #        newmk.print "\t", '$(CC) $(CFLAGS_CLEAN) $(EXTRA_CFLAGS) $(LDFLAGS) $(EXTRA_LDFLAGS) $(PHP_GLOBAL_OBJS:.lo=.o) $(PHP_SAPI_OBJS:.lo=.o) $(PHP_FRAMEWORKS) $(EXTRA_LIBS) $(ZEND_EXTRA_LIBS) $(MH_BUNDLE_FLAGS) -o $@ && cp $@ libs/libphp$(PHP_MAJOR_VERSION).so', "\n"
    #    elsif /^INSTALL_IT =(.*)$/ =~ line
    #        newmk.print "INSTALL_IT = $(mkinstalldirs) '#{prefix}/libexec/apache2' && $(mkinstalldirs) '$(INSTALL_ROOT)/private/etc/apache2' && /usr/sbin/apxs -S LIBEXECDIR='#{prefix}/libexec/apache2' -S SYSCONFDIR='$(INSTALL_ROOT)/private/etc/apache2' -i -a -n php5 libs/libphp5.so", "\n"
    #    else
    #        newmk.print line
    #    end
    #end
    #newmk.close
    #system "cp Makefile.fix Makefile"
    system "make"
    system "make install"
    system "mkdir -p #{prefix}/etc"
    system "cp ./php.ini-production #{prefix}/etc/php.ini"
    if ARGV.include? '--with-fpm'
      system "cp ./sapi/fpm/php-fpm.conf #{prefix}/etc/php-fpm.ini"
    end
    
    if !ARGV.include? '--without-apache'
      puts "Apache module installed at #{prefix}/libexec/apache2/libphp.so"
      puts "You can symlink to it in /usr/libexec/apache2, edit httpd.conf and restart your webserver"
    end
    # system "./configure", "--prefix=#{prefix}", "--disable-debug", "--disable-dependency-tracking"
    # system "cmake . #{std_cmake_parameters}"
    # system "make install"
  end
end

__END__
diff --git a/ext/iconv/iconv.c b/ext/iconv/iconv.c
index 246e1d5..bc90239 100644
--- a/ext/iconv/iconv.c
+++ b/ext/iconv/iconv.c
@@ -183,7 +183,7 @@ static PHP_GINIT_FUNCTION(iconv)
 /* }}} */
 
 #if defined(HAVE_LIBICONV) && defined(ICONV_ALIASED_LIBICONV)
-#define iconv libiconv
+#define iconv iconv
 #endif
 
 /* {{{ typedef enum php_iconv_enc_scheme_t */

diff --git a/ext/mysqli/php_mysqli_structs.h b/ext/mysqli/php_mysqli_structs.h
index 4a7b40c..80b3ed8 100644
--- a/ext/mysqli/php_mysqli_structs.h
+++ b/ext/mysqli/php_mysqli_structs.h
@@ -54,6 +54,7 @@
 #define WE_HAD_MBSTATE_T
 #endif
 
+#define HAVE_ULONG 1
 #include <my_global.h>
 
 #if !defined(HAVE_MBRLEN) && defined(WE_HAD_MBRLEN)

