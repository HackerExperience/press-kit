bower_filter = (type, component, relative_dir_path) ->
  switch component
    when "bootstrap-sass"
      switch type
        when "sass"
          "bootstrap/" + relative_dir_path["assets/stylesheets/".length..]
    when "font-awesome-sass"
      switch type
        when "sass"
          "font-awesome/" + relative_dir_path["assets/stylesheets/".length..]
        when "font"
          "font-awesome/"
    when "jquery" then ""
    when "lightbox2"
      switch type
        when "js" then ""
        when "css"
          "lightbox/" + relative_dir_path["dist/css/".length..]
        when "img"
          "lightbox/" + relative_dir_path["dist/images/".length..]

    else
      relative_dir_path

bower_path_builder = (type, component, full_path) ->
  # The position of the start of the relative folders
  a = (full_path.indexOf component) + component.length + 1

  relative_path =
    if full_path.match ///.*\.[a-zA-Z0-9]/// # is a file
      # Gets the position where the directory path ends
      b = full_path.split("/")
      b.pop()
      b = b.join("/").length

      full_path[a..b]
    else # is a directory
      full_path[a..]

  type + "/" + bower_filter type, component, relative_path

module.exports = (grunt) ->
  grunt.initConfig
    bower:
      install:
        options:
          copy: false
      realloc:
        options:
          install: false
          targetDir: "tmp/bower"
          layout: bower_path_builder
    clean:
      build:
        src: "dist"
      bower:
        src: "tmp/bower"
    compress:
      prod:
        options:
          archive: "dist/release.tar"
          mode: "tar"
        files: [
          expand: true
          cwd: "dist"
          src: ["**/**"]]
    copy:
      css:
        expand: true
        cwd: "tmp/bower/css"
        src: "**/*.css"
        dest: "dist/assets/css"
      font:
        files: [
          {
            expand: true
            cwd: "src/font"
            src: "**/*.{eot,woff,woff2,ttf,svg}"
            dest: "dist/assets/font"}
          {
            expand: true
            cwd: "tmp/bower/font"
            src: "**/*.{eot,woff,woff2,ttf,svg}"
            dest: "dist/assets/font"}]
      js:
        expand: true
        cwd: "tmp/bower/js"
        src: "**/*.js"
        dest: "dist/assets/js/vendor"
    express:
      live:
        options:
          bases: ["dist"]
          livereload: grunt.option('port-live') || true
    imagemin:
      dev:
        options:
          optimizationLevel: 0
        files: x = [
          {
            expand: true
            cwd: "src/img"
            src: ["**/*.{png,jpg,jpeg,gif,svg}"]
            dest: "dist/assets/img"}
          {
            expand: true
            cwd: "tmp/bower/img"
            src: ["**/*.{png,jpg,jpeg,gif,svg}"]
            dest: "dist/assets/img"}]
      prod:
        options:
          optimizationLevel: 7
          progressive: false
          interlaced: false
        files: x
    jade:
      dev:
        options:
          pretty: true
          data: (dest, src) ->
            (data = (env) ->
              conf = grunt.file.readJSON "src/jade/variables.json"
              conf.env = env
              conf) "dev"
        files: x  = [
          expand: true
          cwd: "src/jade"
          src: ["**/*.jade", "!includes/**"]
          dest: "dist"
          ext: ".html"]
      prod:
        options:
          pretty: false
          compileDebug: false
          data: (dest, src) ->
            (data = (env) ->
              conf = grunt.file.readJSON "src/jade/variables.json"
              conf.env = env
              conf) "prod"
        files: x
    sass:
      dev:
        options:
          style: "nested"
          sourcemap: "file"
          trace: true
          unixNewlines: true
          compass: true
          loadPath: x = ["tmp/bower/sass"]
        files: y = [
          expand: true
          cwd: "src/sass"
          src: ["**/*.scss"]
          dest: "dist/assets/css"
          ext: ".css"]
      prod:
        options:
          style: "compressed"
          sourcemap: "none"
          unixNewlines: true
          compass: true
          loadPath: x
        files: y
    parallel:
      options:
        grunt: true
      dev:
        tasks: ["copy", "imagemin:dev", "sass:dev", "jade:dev", "uglify:dev"]
      prod:
        tasks: ["copy", "imagemin:prod", "sass:prod", "jade:prod", "uglify:prod"]
    uglify:
      dev:
        options:
          preserveComments: "all"
          beautify: false
          mangle: false
          sourceMap: true
          sourceMapIncludeSources: true
        files: x = [
          {
            "dist/assets/js/custom.js": ["src/js/custom_js/**/*.js"]}
          {
            expand: true
            cwd: "src/js"
            src: ["*.js"]
            dest: "dist/assets/js"
            ext: ".js"}]
      prod:
        options:
          preserveComments: "some"
          compress:
            drop_console: true
        files: x
    watch:
      options:
        spawn: false
      img:
        files: ["src/img/**/*.{png,jpg,jpeg,gif,svg}"]
        tasks: ["imagemin:dev"]
      jade:
        files: ["src/jade/**/*.jade", "src/jade/variables.json"]
        tasks: ["jade:dev"]
      js:
        files: ["src/js/**/*.js"]
        tasks: ["uglify:dev"]
      sass:
        files: ["src/sass/**/*.scss"]
        tasks: ["sass:dev"]
      watch:
        options:
          spawn: false
          reload: true
        files: ["Gruntfile.coffee"]

  grunt.loadNpmTasks 'grunt-bower-task'
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-contrib-compress'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-contrib-imagemin'
  grunt.loadNpmTasks 'grunt-contrib-jade'
  grunt.loadNpmTasks 'grunt-contrib-sass'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-express'
  grunt.loadNpmTasks 'grunt-parallel'

  grunt.registerTask "live", ["bower", "parallel:dev", "express:live", "watch"]
  grunt.registerTask "release", ["clean", "bower", "parallel:prod", "compress"]
