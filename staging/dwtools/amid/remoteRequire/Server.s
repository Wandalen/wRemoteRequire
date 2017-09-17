( function _RemoteRequireServer_s_() {

  'use strict';

  if( typeof module !== 'undefined' )
  {
    require( 'wTools' );
    require( 'wFiles' );
    require( 'wConsequence' );
  }

  //

  var _ = wTools;
  var Parent = null;
  var pathNativize = _.fileProvider.pathNativize;
  var rootDir = pathNativize( _.pathResolve( __dirname, '../../..' ) );
  var statics = pathNativize( _.pathJoin( rootDir, 'staging/dwtools/amid/launcher/static' ) );
  var modules = pathNativize( _.pathJoin( rootDir, 'node_modules' ) );
  var resolve = require( 'resolve' );

  var Self = function wRemoteRequireServer( o )
  {
    if( !( this instanceof Self ) )
    if( o instanceof Self )
    return o;
    else
    return new( _.routineJoin( Self, Self, arguments ) );
    return Self.prototype.init.apply( this,arguments );
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
    self.con = new wConsequence().give();

    if( !self.files )
    self.files = {};
    if( !self.records )
    self.records = {};
    if( !self.requests )
    self.requests = [];

    _.assert( self.rootDir, 'rootDir is required' );
  }

  //

  function start()
  {
    var self = this;

    process.on( 'SIGINT', function()
    {
      self.con
      .doThen( () => self.stop() )
      .doThen( () => process.exit() );
    });

    self.con
    .seal( self )
    .ifNoErrorThen( self._getPort )
    .ifNoErrorThen( self._start )

    return self.con;
  }

  //

  function stop()
  {
    var self = this;

    var con = new wConsequence().give();

    if( self.server && self.server.isRunning )
    con.doThen( () => self.server.close() );

    return con;
  }

  //

  function _start()
  {
    var self = this;

    if( !self.app )
    {
      _.assert( _.numberIs( self.serverPort ) );

      var con = new wConsequence();
      var express = require( 'express' );
      var app = express();
      self.server = require( 'http' ).createServer( app );

      if( !self.resolve )
      self.resolve = require( 'resolve' );

      app.post( '/require', function( req, res )
      {
        self._resolve( req,res );
      });

      self.server.listen( self.serverPort, function ()
      {
        if( self.verbosity >= 3 )
        logger.log( 'Server started:', 'http://127.0.0.1:'+ self.serverPort );
        self.serverIsRunning = true;
        con.give();
      });
    }
    else
    {
      self.app.post( '/require', function( req, res )
      {
        self._resolve( req,res );
      });
    }

    return con;
  }

  //

  function _resolve( req, res )
  {
    var self = this;

    var data = '';
    req.on( 'data', ( chunk ) => data += chunk.toString() )
    req.on( 'end', () =>
    {
      try
      {
        data = JSON.parse( data );
      }
      catch( err )
      {
        _.errLog( err );
      }

      self.requests.push( data );

      if( !_.objectIs( data ) || data.require === undefined )
      {
        res.send({ fail : 1 });
      }

      if( self.verbosity > 1 )
      console.log( 'data : ', data  )

      var baseDir;
      var filePath;

      if( self.files[ data.token ] )
      {
        var pathByToken = self.files[ data.token ].filePath;
        filePath = self.records[ pathByToken ].absolute;
        baseDir = _.pathDir( filePath );
      }
      else
      {
        baseDir = self.rootDir;
      }

      var resolved = null;

      // if( _.strBegins( filePath, '/static' ) )
      // {
      //   filePath = _.pathJoin( statics, _.strRemoveBegin( filePath, '/static/' ) );
      // }

      // if( _.strBegins( filePath, '/modules' ) )
      // {
      //   filePath = _.pathJoin( modules, _.strRemoveBegin( filePath, '/modules/' ) );
      // }

      if( self.verbosity > 1 )
      {
        console.log( 'baseDir', baseDir );
        console.log( 'filePath', filePath );
      }

      if( !resolved )
      resolved = _.pathResolve( _.pathJoin( baseDir, data.require ) );

      if( !_.fileProvider.fileStat( resolved ) )
      {
        resolved = null;

        try
        {
          resolved = resolve.sync( data.require, { basedir: baseDir });
        }
        catch( err )
        {
          // _.errLog( err );
        }
      }

      if( resolved && _.fileProvider.fileStat( resolved ) )
      {
        if( _.pathCommon( [ self.rootDir, resolved ] ) !== self.rootDir )
        throw _.err( 'Required module path is out of rootDir path: ', self.rootDir );

        if( self.verbosity > 1 )
        console.log( 'resolved for : ', data.require );

        var info = self.addFile( resolved );
        info.code = _.fileProvider.fileRead( resolved );

        res.send( JSON.stringify( info ) );
      }
      else
      {
        if( self.verbosity > 1 )
        console.log( 'resolve failded for : ', data.require, baseDir );

        res.send({ fail : 1 });
      }
    })
  }

  //

  function _getPort()
  {
    var self = this;

    if( self.serverPort )
    var args = [ self.serverPort ];

    var getPort = require( 'get-port' );

    var con = wConsequence.from( getPort.apply( this, args ) );

    con.doThen( ( err, port ) =>
    {
      self.serverPort = port
    });

    return con;
  }

  //

  function addFile( filePath )
  {
    var self = this;

    var token = _.idGenerateDate();

    if( !self.rootDir )
    self.rootDir = _.pathDir( filePath );

    var o = { fileProvider :  _.fileProvider };
    var recordOptions = _.FileRecordOptions( o, { dir : rootDir } );

    var record = _.fileProvider.fileRecord( filePath, recordOptions );
    self.records[ record.absolute ] = record;
    self.files[ token ] =
    {
      filePath : record.absolute,
    }
    return { token : token, filePath : record.relative };
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
    requests : null
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
    _resolve : _resolve,
    _getPort : _getPort,

    addFile : addFile,

    // relationships

    Composes : Composes,
    Restricts : Restricts,
    Statics : Statics,
  }

  //

  _.classMake
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
