/**
 * Created by 23rd and Walnut for Codebasehero.com
 * www.23andwalnut.com
 * www.codebasehero.com
 * User: Saleem El-Amin
 * Date: 6/11/11
 * Time: 6:41 AM
 *
 * Version: 1.01
 * License: You are free to use this file in personal and commercial products, however re-distribution 'as-is' without prior consent is prohibited.
 */

(function($) {
    $.fn.ttwMusicPlayer = function(playlist, userOptions) {
        var $self = this, defaultOptions, options, cssSelector, appMgr, playlistMgr, interfaceMgr, playlist,
                layout, ratings, myPlaylist, current;

        cssSelector = {
            jPlayer: "#jquery_jplayer",
            jPlayerInterface: '.jp-interface',
            playerPrevious: ".jp-interface .jp-previous",
            playerNext: ".jp-interface .jp-next",
            trackList:'.tracklist',
            tracks:'.tracks',
            track:'.track',
            trackRating:'.rating-bar',
            trackInfo:'.track-info',
            rating:'.rating',
            ratingLevel:'.rating-level',
            ratingLevelOn:'.on',
            title: '.title',
            duration: '.duration',
            buy:'.buy',
            buyNotActive:'.not-active',
            playing:'.playing',
            moreButton:'.more',
            player:'.player',
            artist:'.artist',
            artistOuter:'.artist-outer',
            albumCover:'.img',
            description:'.description',
            descriptionShowing:'.showing'
        };

        defaultOptions = {
            ratingCallback:null,
            currencySymbol:'$',
            tracksToShow:5,
            autoPlay:false,
            jPlayer:{}
        };

        options = $.extend(true, {}, defaultOptions, userOptions);

        myPlaylist = playlist;

        current = 0;

        appMgr = function() {
            playlist = new playlistMgr();
            layout = new interfaceMgr();

            layout.buildInterface();
            playlist.init(options.jPlayer);

            //don't initialize the ratings until the playlist has been built, which wont happen until after the jPlayer ready event
            $self.bind('mbPlaylistLoaded', function() {
                $self.bind('mbInterfaceBuilt', function() {
//                    ratings = new ratingsMgr();
                });
                layout.init();

            });
        };

        playlistMgr = function() {

            var playing = false, markup, $myJplayer = {},$tracks,showHeight = 0,remainingHeight = 0,$tracksWrapper, $more;

            markup = {
                listItem:'<li class="track nav nav-tabs nav-stacked">' +
                            '<a href="#" class="title"></a>' +
//                            '<span class="duration"></span>' +
//                            '<span class="rating"></span>' +
                        '</li>',
                ratingBar:'<span class="rating-level rating-bar"></span>'
            };

            function init(playlistOptions) {

                $myJplayer = $('.ttw-music-player .jPlayer-container');


                var jPlayerDefaults, jPlayerOptions;

                jPlayerDefaults = {
                    swfPath: "jquery-jplayer",
                    supplied: "mp3, oga",
                    solution:'html, flash',
                    cssSelectorAncestor:  cssSelector.jPlayerInterface,
                    errorAlerts: false,
                    warningAlerts: false
                };

                //apply any user defined jPlayer options
                jPlayerOptions = $.extend(true, {}, jPlayerDefaults, playlistOptions);

                $myJplayer.bind($.jPlayer.event.ready, function() {

                    //Bind jPlayer events. Do not want to pass in options object to prevent them from being overridden by the user
                    $myJplayer.bind($.jPlayer.event.ended, function(event) {
                        playlistNext();
                    });

                    $myJplayer.bind($.jPlayer.event.play, function(event) {
                        $myJplayer.jPlayer("pauseOthers");
                        $tracks.eq(current).addClass(attr(cssSelector.playing)).siblings().removeClass(attr(cssSelector.playing));
                    });

                    $myJplayer.bind($.jPlayer.event.playing, function(event) {
                        playing = true;
                    });

                    $myJplayer.bind($.jPlayer.event.pause, function(event) {
                        playing = false;
                    });

                    //Bind next/prev click events
                    $(cssSelector.playerPrevious).click(function() {
                        playlistPrev();
                        $(this).blur();
                        return false;
                    });

                    $(cssSelector.playerNext).click(function() {
                        playlistNext();
                        $(this).blur();
                        return false;
                    });

                    $self.bind('mbInitPlaylistAdvance', function(e) {
                        var changeTo = this.getData('mbInitPlaylistAdvance');
                        if (changeTo != current) {
                            current = changeTo;
                            playlistAdvance(current);
                        }
                        else {
                            if (!$myJplayer.data('jPlayer').status.srcSet) {
                                playlistAdvance(0);
                            }
                            else {
                                togglePlay();
                            }
                        }
                    });

                     buildPlaylist();
                    //If the user doesn't want to wait for widget loads, start playlist now
                    $self.trigger('mbPlaylistLoaded');

                    playlistInit(options.autoplay);
                });

                //Initialize jPlayer
                $myJplayer.jPlayer(jPlayerOptions);
            }

            function playlistInit(autoplay) {
                current = 0;

                if (autoplay) {
                    playlistAdvance(current);
                }
                else {
                    playlistConfig(current);
                    $self.trigger('mbPlaylistInit');
                }
            }

            function playlistConfig(index) {
                current = index;
                $myJplayer.jPlayer("setMedia", myPlaylist[current]);
            }

            function playlistAdvance(index) {
                playlistConfig(index);

                $self.trigger('mbPlaylistAdvance');
                $myJplayer.jPlayer("play");
            }

            function playlistNext() {
                var index = (current + 1 < myPlaylist.length) ? current + 1 : 0;
                
                playlistAdvance(index);
            }

            function playlistPrev() {
                var index = (current - 1 >= 0) ? current - 1 : myPlaylist.length - 1;
                playlistAdvance(index);
            }

            function togglePlay() {
                if (!playing)
                    $myJplayer.jPlayer("play");
                else $myJplayer.jPlayer("pause");
            }

            function buildPlaylist() {
                $('.track-title').click(function(e) {
//                	if( (!$.browser.msie &&  == 0) || ($.browser.msie && e.button == 1) ) {
                	if( e.button == 0 ) {
                		e.preventDefault();
                    	var id = parseInt($(this).attr('rel'));
                    	playlistAdvance(id);
    				}
                });
            }

            function duration(index) {
                return !isUndefined(myPlaylist[index].duration) ? myPlaylist[index].duration : '-';
            }

            return{
                init:init,
                playlistInit:playlistInit,
                playlistAdvance:playlistAdvance,
                playlistNext:playlistNext,
                playlistPrev:playlistPrev,
                togglePlay:togglePlay,
                $myJplayer:$myJplayer
            };

        };

        interfaceMgr = function() {

            var $player, $title, $artist, $albumCover;


            function init() {
                $player = $(cssSelector.player),
                        $title = $player.find(cssSelector.title),
                        $artist = $player.find(cssSelector.artist),
                        $albumCover = $player.find(cssSelector.albumCover);

                setDescription();

                $self.bind('mbPlaylistAdvance mbPlaylistInit', function() {
                    setTitle();
                    setArtist();
                    setCover();
                });
            }

            function buildInterface() {
                var markup, $interface;

                //I would normally use the templating plugin for something like this, but I wanted to keep this plugin's footprint as small as possible
                markup= '<div class="ttw-music-player" style="max-height: 260px;">' +
                        '<div class="player jp-interface">' +
                        
                        '   <div class="album-cover" style="width:260px; z-index: 1; position: relative;">' +
                        '   	<span class="img"></span>' +
                        '      	<span class="highlight"></span>' +
                        '   </div>' +
                        
                        '	<div id="shara-player" style="width:260px;Z-index:2; position: relative; opacity:0.85;">' +
                        '   	<div class="track-info">' +
                        '           <div  style="background-color: white; display: inline; float:left; padding-right: 10px;"><h3 class="title"></h3></div>' +
                        '           <div class="artist-outer pull-left" style="background-color: white; display: inline-block;">By <span class="artist" style="font-size:1.5em;"></span></div><br/>' +


                        '			<div class="pull-right" style="background-color: white; margin: 3px; display: inline; float:right z-index:5"><span class="jp-current-time"></span> / ' +
	                    '					<span class="jp-duration"></span"></div>' +
    	                ' 			</div>' +
                        

    							'<br/><br/><br/><br/><br/><br/><br/><br/><br/>'+
                        '			<div class="progress-wrapper">' +
                        '                <div class="progress jp-seek-bar">' +
                        '                    <div class="elapsed jp-play-bar"></div>' +
                        '                </div>' +
                        '           </div>' +
                        
									'<div align="center"><div class="playback btn-group">' +
										'<button class="prev jp-previous"><i class="icon-step-backward"></i></button>'+
										'<button class="pause jp-pause"><i class="icon-pause"></i></button>'+
										'<button class="play jp-play"><i class="icon-play"></i></button>'+
										'<button class="next jp-next"><i class="icon-step-forward"></i></button>'+
									'</div></div>'+
									
/*
                        '       	<div class="row-fluid" style="background-color: white; width:50%;">Vol: <br/><div class="progress-wrapper">' +
                        '                <div class="progress jp-volume-bar">' +
                        '                    <div class="elapsed jp-volume-bar-value"></div>' +
                        '                </div>' +
                        '            </div></div>' +
*/

                        '    	<p class="description"></p>' +
                        '   	<div class="jPlayer-container"></div>' +
                        '	</div>' +
                        '</div></div>';

                $interface = $(markup).css({display:'none', opacity:0}).appendTo($self).slideDown('slow', function() {
                    $interface.animate({opacity:1});

                    $self.trigger('mbInterfaceBuilt');
                });
            }

            function setTitle() {
                $title.html(trackName(current));
            }

            function setArtist() {
                if (isUndefined(myPlaylist[current].artist))
                    $artist.parent(cssSelector.artistOuter).animate({opacity:0}, 'fast');
                else {
                    $artist.html(myPlaylist[current].artist).parent(cssSelector.artistOuter).animate({opacity:1}, 'fast');
                }
            }

            function setCover() {
                $albumCover.animate({opacity:0}, 'fast', function() {
                	var cover = myPlaylist[current].cover || '/i/NoCover.jpg';
                    if (!isUndefined(cover)) {
                        var now = current;
                        $('<img src="' + cover + '" alt="album cover" />', this).imagesLoaded(function(){
                            if(now == current)
                                $albumCover.html($(this)).animate({opacity:1});
                            $('#shara-player').css({'top': '-'+($('.album-cover').height())+'px'});
                             $('#shara-player').css({'display': 'block'});
                            $('.player').height('260px');
 

                         });
                     } else {
                     	// $('#shara-player').css({'display': 'block'});
                     	// $('#shara-player').css({'display': 'block'});
                    }
                });
            }

            function setDescription() {
                if (!isUndefined(options.description))
                    $self.find(cssSelector.description).html(options.description).addClass(attr(cssSelector.descriptionShowing)).slideDown();
            }

            return{
                buildInterface:buildInterface,
                init:init
            }

        };

        /** Common Functions **/
        function trackName(index) {
            if (!isUndefined(myPlaylist[index].title))
                return myPlaylist[index].title;
            else if (!isUndefined(myPlaylist[index].mp3))
                return fileName(myPlaylist[index].mp3);
            else if (!isUndefined(myPlaylist[index].oga))
                return fileName(myPlaylist[index].oga);
            else return '';
        }

        function fileName(path) {
            path = path.split('/');
            return path[path.length - 1];
        }


        /** Utility Functions **/
        function attr(selector) {
            return selector.substr(1);
        }

        function runCallback(callback) {
            var functionArgs = Array.prototype.slice.call(arguments, 1);

            if ($.isFunction(callback)) {
                callback.apply(this, functionArgs);
            }
        }

        function isUndefined(value) {
            return typeof value == 'undefined';
        }

        appMgr();
    };
})(jQuery);

(function($) {
// $('img.photo',this).imagesLoaded(myFunction)
// execute a callback when all images have loaded.
// needed because .load() doesn't work on cached images

// mit license. paul irish. 2010.
// webkit fix from Oren Solomianik. thx!

// callback function is passed the last image to load
//   as an argument, and the collection as `this`


    $.fn.imagesLoaded = function(callback) {
        var elems = this.filter('img'),
                len = elems.length;

        elems.bind('load',
                function() {
                    if (--len <= 0) {
                        callback.call(elems, this);
                    }
                }).each(function() {
            // cached images don't fire load sometimes, so we reset src.
            if (this.complete || this.complete === undefined) {
                var src = this.src;
                // webkit hack from http://groups.google.com/group/jquery-dev/browse_thread/thread/eee6ab7b2da50e1f
                // data uri bypasses webkit log warning (thx doug jones)
                this.src = "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==";
                this.src = src;
            }
        });

        return this;
    };
})(jQuery);