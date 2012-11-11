{spawn, exec} = require 'child_process'
fs = require "fs"
path = require "path"
wrench = require 'wrench'
exists = fs.exists or path.exists

module.exports = class ImageOptimzer
  brunchPlugin: yes
  png : [".png", ".bmp", ".gif", ".pnm", ".tiff"]
  jpegs : [".jpg", "jpeg"]    
  _PNGBin : 'optipng'
  _JPGBin: 'jpegtran'  
  constructor: (@config) -> 
    exec "#{@_PNGBin} --version", (error, stdout, stderr) =>
      console.error "You need to have optipng on your system" if error        

    exec "#{@_JPGBin} -v", (error, stdout, stderr) =>
      console.error "You need to have jpegtran on your system" if error        

    null

  onCompile: (generatedFiles) ->
    return unless @config.minify    
    files = wrench.readdirSyncRecursive @config.paths.public    
    
    # Add Images
    files = files.map (file) =>
      @config.paths.public + '/' + file

    # Scan for Png Files
    pngfiles = files.filter((file) =>
      !!~@png.indexOf(path.extname(file).toLowerCase())
    )

    # Scan for JPG Files
    jpgfiles = files.filter((file) =>
      !!~@jpegs.indexOf(path.extname(file).toLowerCase())
    )    	
    # Compress PNG Files
    if pngfiles.length
      pngFileSizeBefore = @calculateSizeFromImages(pngfiles)      
      @optimizePNG pngfiles, (error, result) =>
        pngFileSizeAfter = @calculateSizeFromImages(pngfiles)  
        percent = (((pngFileSizeBefore/pngFileSizeAfter)-1)*100).toFixed(2)
        console.log 'Compressed ' + pngfiles.length + ' png files: saved '+percent+'% (before: ' + pngFileSizeBefore + ' - after: ' + pngFileSizeAfter + ' bytes)'
    ###    
    # Compress JPG Files
    if jpgfiles.length
      jpgFileSizeBefore = @calculateSizeFromImages(jpgfiles)      
      @optimizeJPG jpgfiles, (error, result) =>        
        jpgFileSizeAfter = @calculateSizeFromImages(jpgfiles)  
        percent = (((jpgFileSizeBefore/jpgFileSizeAfter)-1)*100).toFixed(2)
        console.log 'Compressed ' + jpgfiles.length + ' jpg files: saved '+percent+'% (before: ' + jpgFileSizeBefore + ' - after: ' + jpgFileSizeAfter + ' bytes)'
    ###
    return this

  calculateSizeFromImages: (files) ->
    size = 0;
    files.forEach (file) ->
      size += fs.statSync(file).size

    return size

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
