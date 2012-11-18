{spawn, exec} = require 'child_process'
fs = require "fs"
path = require "path"
sysPath = require 'path'
smushit  = require 'node-smushit'
exists = fs.exists or path.exists

module.exports = class ImageOptimzer
  brunchPlugin: yes
  png : [".png", ".bmp", ".gif", ".pnm", ".tiff"]
  jpegs : [".jpg", "jpeg"]    
  _PNGBin : 'optipng'
  _JPGBin: 'jpegtran'  
  imagePath: 'images'
  constructor: (@config) ->     
    @imagePath = @config.imageoptimizer.path if @config.imageoptimizer?.path 
    @imagePath = sysPath.join @config.paths.public, @imagePath    

    #console.log @imagePath @config.paths.public
    unless @config.imageoptimizer?.smushit
      exec "#{@_PNGBin} --version", (error, stdout, stderr) =>
        console.error "You need to have optipng and jpegtran on your system" if error
    null

  onCompile: (generatedFiles) ->    
    return unless @config.minify
    if @config.imageoptimizer?.smushit
      smushit.smushit @imagePath, recursive: true
    else      
      files = @readDirSync(@imagePath)

      # Compress PNG Files
      if files.png.length
        @optimizePNG files.png, (error, result) =>
          console.log "Compressed #{files.png.length} png files via #{@_PNGBin}"

      # Compress JPG Files
      if files.jpeg.length
        filesjpeg = files.jpeg.slice(0);
        @optimizeJPG files.jpeg, (error, result) =>        
          console.log "Compressed #{filesjpeg.length} jpeg files via #{@_JPGBin}"

  calculateSizeFromImages: (files) ->
    size = 0;
    files.forEach (file) ->
      size += fs.statSync(file).size

    return size


  readDirSync: (baseDir) ->
    ## Mostly borrowed from npm wrench. thanks
    baseDir = baseDir.replace(/\/$/, "")
    fileList = {
      png: []
      jpeg: []
    }
    readdirSyncRecursive = (baseDir) ->
      files = []
      isDir = (fname) ->
        fs.statSync(sysPath.join(baseDir, fname)).isDirectory()
      prependBaseDir = (fname) ->        
        sysPath.join baseDir, fname
      
      curFiles = fs.readdirSync(baseDir)      
      nextDirs = curFiles.filter(isDir)
      curFiles = curFiles.map(prependBaseDir)      
      files = files.concat(curFiles)      
      files = files.concat(readdirSyncRecursive(sysPath.join(baseDir, nextDirs.shift())))  while nextDirs.length
      
      files
    
    readdirSyncRecursive(baseDir).forEach((filepath) =>
      fileList.png.push(filepath) if !!~@png.indexOf(path.extname(filepath).toLowerCase())
      fileList.jpeg.push(filepath) if !!~@jpegs.indexOf(path.extname(filepath).toLowerCase())
    )

    return fileList

  optimizeJPG: (files,  callback) ->
    error = null
    result = ''    
    tmpfile = 'jpgtmp.jpg'
    options = [    
      '-copy'
      'none'
      '-optimize'
      '-outfile'
      'jpgtmp.jpg'
    ] 

    (run = (file) =>      
      return clean() unless file
      args = options.concat file      
      wStream = null

      jpegtran = spawn @_JPGBin, args
      jpegtran.on 'exit', (code) =>        
        return if code
        wStream = fs.createWriteStream(file, {flags: 'w'}).pipe(fs.createReadStream(tmpfile))
        wStream.on "close", (test) =>
          run files.shift()
    ) files.shift()

    clean = =>      
      exists tmpfile, (exists) =>
        return callback(result, error) unless exists    
        fs.unlink tmpfile, (err) =>
          callback(result, error)

    return this

  optimizePNG: (files, callback) ->
    error = null
    result = ''
    options = [     
    ]

    args = options.concat files
    optipng = spawn @_PNGBin, args
    optipng.stderr.on 'data', (buffer) ->
      result += buffer.toString()

    onExit = (code) -> callback error
    optipng.on 'close', onExit

    null
