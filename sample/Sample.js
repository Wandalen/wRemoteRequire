require( 'wremoterequire' );
var _ = wTools;
var express = require( 'express' );
var app = express();
var server = require( 'http' ).createServer( app );
var remoteRequire = new wRemoteRequireServer
({
  app : app,
  verbosity : 5,
  rootDir : __dirname
});
remoteRequire.start();

var modules = _.join( _.resolve( __dirname, '../' ), 'node_modules' );
var staging = _.join( _.resolve( __dirname, '../' ), 'staging' );

app.use( '/modules', express.static( modules ));
app.use( '/staging', express.static( staging ));

app.get( '/', function ( req, res )
{
  res.sendFile( _.join( __dirname, 'Sample.html' ) );
});

server.listen( 8080, function ()
{
  _.shell( 'open http://localhost:8080' );
});
