( function _RemoteRequireServer_s_() {

'use strict';

if( typeof module !== 'undefined' )
{

  let _ = require( '../../Tools.s' );

  if( !_.nameFielded )
  try
  {
    require( './NameTools.s' );
  }
  catch( err )
  {
  }

  _.include( 'wFiles' );
  _.include( 'wConsequence' );

  var resolve = require( 'resolve' );
  var findRoot = require( 'find-root' );

}

//

let _ = wTools;
let Parent = null;

var rootDir = _.fileProvider.path.nativize( _.path.resolve( __dirname, '../../..' ) );
// var statics = _.fileProvider.path.nativize( _.path.join( rootDir, 'staging/wtools/amid/launcher/static' ) );
var modules = _.fileProvider.path.nativize( _.path.join( rootDir, 'node_modules' ) );
var includeDir = _.path.join( modules, 'wTools/staging/wtools/abase/layer2' );

let Self = function wRemoteRequireServer( o )
{
  return _.workpiece.construct( Self, this, arguments );
}

Self.nameShort = 'RemoteRequireServer';

//

function init( o )
{
  var self = this;

  _.assert( arguments.length === 0 | arguments.length === 1 );

  if( o )
  self.copy( o )

  if( !self.con )
  self.con = new _.Consequence().take( null );

  if( !self.records )
  self.records = {};

  if( !self.requests )
  self.requests = [];

  if( !self.files )
  self.files = {};

  if( !self.tokensByFileName )
  self.tokensByFileName = {};

  if( !self.processed )
  self.processed = {};

  _.assert( self.rootDir, 'rootDir is required' );
}

//

function start()
{
  var self = this;

  process.on( 'SIGINT', function()
  {
    self.con
    .then( () => self.stop() )
    .then( () => process.exit() );
  });

  self.con
  // .seal( self )
  .ifNoErrorThen( _.routineSeal( self, self._portGet ) )
  .ifNoErrorThen( _.routineSeal( self, self._start ) )

  return self.con;
}

//

function stop()
{
  var self = this;

  var con = new _.Consequence().take( null );

  if( self.server && self.server.isRunning )
  con.then( () => self.server.close() );

  return con;
}

//

function _start()
{
  var self = this;

  if( !self.app )
  {
    _.assert( _.numberIs( self.serverPort ) );

    var con = new _.Consequence();
    var express = require( 'express' );
    var app = express();
    self.server = require( 'http' ).createServer( app );

    if( !self.resolve )
    self.resolve = require( 'resolve' );

    app.post( '/require', function( req, res )
    {
      self._require( req,res );
    });

    self.server.listen( self.serverPort, function ()
    {
      if( self.verbosity >= 3 )
      logger.log( 'Server started:', 'http://127.0.0.1:'+ self.serverPort );
      self.serverIsRunning = true;
      con.take( null );
    });

    return con;
  }
  else
  {
    self.app.get( '/require', function( req, res )
    {
      self._require( req,res );
    });

    self.app.get( '/resolve', function( req, res )
    {
      self._resolve( req,res );
    });

    self.app.get( '/processed*', function( req, res )
    {
      self._processed( req,res );
    });

    return true;
  }

}

//

function _require( req, res )
{
  var self = this;

  var filePathResolved;

  if( req.query.token === "undefined" )
  req.query.token = undefined;

  debugger

  try
  {
    var baseDir;

    if( !req.query.local )
    {
      if( req.query.token )
      if( self.files[ req.query.token ] )
      {
        var byToken = self.files[ req.query.token ].filePath;
        var filePath = self.records[ byToken ].absolute;
        baseDir = _.path.dir( filePath );
      }

      if( baseDir === undefined )
      var baseDir = self.rootDir;
    }
    else
    {
      baseDir = __dirname;
    }

    debugger

    filePathResolved = resolve.sync( req.query.package, { basedir: _.fileProvider.path.nativize( baseDir ) });

    var packageRootDir = _.path.dir( findRoot( filePathResolved ) );

    //normalize resolved
    filePathResolved = _.path.normalize( filePathResolved );

    var filePathShort = _.strRemoveBegin( _.strRemoveBegin( filePathResolved, packageRootDir ), '/' );
    var info = self.fileAdd( filePathResolved, filePathShort );

    var file = self.fileComplement( filePathResolved, filePathShort, info, req.query.token )

    self.processed[ info.token ] = file;

    res.send( JSON.stringify( { code : file, token : info.token, filePath : filePathResolved } ) );
  }
  catch( err )
  {
    if( self.verbosity >= 3 )
    _.errLog( err );

    res.send({ fail : 1 });
  }
}

//

function _resolve( req, res )
{
  var self = this;

  var self = this;

    var filePathResolved;

    try
    {
      var baseDir;

      if( req.query.fromInclude )
      baseDir = includeDir;
      else
      baseDir = self.rootDir;

      filePathResolved = resolve.sync( req.query.package, { basedir: baseDir });

      res.send( JSON.stringify( { filePath : filePathResolved } ) );
    }
    catch( err )
    {
      if( self.verbosity >= 3 )
      _.errLog( err );

      res.send({ fail : 1 });
    }

}

//

function _processed( req, res )
{
  var self = this;

  var filePathShort = _.strRemoveBegin( req.params[ 0 ], '/' );

  var token = self.tokensByFileName[ filePathShort ];

  if( token )
  {
    var file = self.processed[ token ];
    res.send( file )
  }
  else
  res.send( 'file not found' );
}

//

function _portGet()
{
  var self = this;

  if( self.serverPort )
  return self.serverPort;

  var args = [ self.serverPort ];

  var getPort = require( 'get-port' );

  var con = _.Consequence.From( getPort.apply( this, args ) );

  con.finally( ( err, port ) =>
  {
    self.serverPort = port
    return null;
  });

  return con;
}

//

function fileAdd( filePath, filePathShort )
{
  var self = this;

  if( self.records[ filePath ] )
  {
    var tokens = _.mapOwnKeys( self.files );
    for( var i = 0; i < tokens.length; i++ )
    {
      var token = tokens[ i ];
      var file = self.files[ token ];
      if( file.filePath === self.records[ filePath ].absolute )
      {
        return { token : token, filePath : self.records[ filePath ].relative }
      }
    }
  }

  var token = _.idWithDate();

  if( !self.rootDir )
  self.rootDir = _.path.dir( filePath );

  debugger
  var o = { defaultFileProvider :  _.fileProvider, filter : null, dirPath : self.rootDir };
  var factory = _.FileRecordFactory.TollerantFrom( o ).form();
  var record = factory.record({ input : filePath, factory : factory })
  // var record = _.fileProvider.fileRecord( filePath, recordOptions );
  self.records[ record.absolute ] = record;
  self.files[ token ] =
  {
    filePath : record.absolute,
  }

  self.tokensByFileName[ filePathShort ] = token;

  return { token : token, filePath : record.relative };
}

//

function fileComplement( filePath, filePathShort, info, parent )
{
  var self = this;
  var file = _.fileProvider.fileRead( filePath );

  var sourceUrl = `//@ sourceURL=http://localhost:${self.serverPort}/processed/${filePathShort}\n`;
  var _parent = parent ? `RemoteRequire.parents.value["${parent}"]` : undefined;

  var _module =
  `var module =
{
  exports : RemoteRequire.exports.value["${info.token}"],
  parent : ${_parent},
  isBrowser : true
};\n`;

  var require =
  `var require = wTools.routineJoin
({
  token : "${info.token}",
  script : document.currentScript
  },
  RemoteRequire.require
);\n`;

  var fileName = _.path.name({ path : filePath, full : 1 } );
  var wrapperName  =  fileName.replace( /<|>| :|\.|"|'|\/|\\|\||\&|\?|\*|\n|\s/g, '_' )

  /* var wrapper =
  `${sourceUrl}

( function ${wrapperName} () {

debugger;
${_module}
${require}

//

${file}

})();` */

/* var wrapper =
  `${sourceUrl}

( function ${wrapperName} () {
  debugger;

//

${file}

})();` */

var wrapper =
`${sourceUrl}
//debugger;
${file}
`
  return wrapper;
}

// --
// relationship
// --

var Composes =
{
  server : null,
  app : null,
  serverPort : null,
  verbosity : 1,
  rootDir : null,
}

var Restricts =
{
  resolve : null,
  serverIsRunning : false,
  con : null,
  files : null,
  records : null,
  requests : null,
  tokensByFileName : null
}

var Statics =
{
}

// --
// prototype
// --

var Proto =
{

  init : init,

  start : start,
  stop : stop,
  _start : _start,
  _require : _require,
  _resolve : _resolve,
  _portGet : _portGet,
  _processed : _processed,

  fileAdd : fileAdd,
  fileComplement : fileComplement,

  // relationships

  Composes : Composes,
  Restricts : Restricts,
  Statics : Statics,
}

//

_.classDeclare
({
  cls : Self,
  parent : Parent,
  extend : Proto,
});

wCopyable.mixin( Self );

if( typeof module !== 'undefined' )
module[ 'exports' ] = Self;

_global_[ Self.name ] = wTools[ Self.nameShort ] = Self;

})();
