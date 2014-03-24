$(function() {
  var getKeys = function(obj) {
    var key, keys;
    keys = [];
    for (key in obj) {
      keys.push(key);
    }
    return keys;
  };
  
  // Chrome fires popstate on page load, Firefox doesn't
  var popstateReady = false;
  
  var setupTweetButton = function() {
    if (typeof(twttr) == "undefined") {
      return false;
    }
    
    $("#tweetButton iframe").remove();
    var tweetMessage = $("#q").val() || 'Analyzing trends over 30+ seasons of Jeopardy!'
    var tweetContent = ('#JeopardyNgrams - ' + tweetMessage).substr(0, 119);
    var newButton = $("<a></a>").addClass("twitter-share-button").
                                 attr("href", "http://twitter.com/share").
                                 attr("data-url", window.location.href).
                                 attr("data-text", tweetContent);

    $("#tweetButton").append(newButton);
    twttr.widgets.load();
  };
  
  $.getScript("//platform.twitter.com/widgets.js", function() {
    setupTweetButton();
  });
  
  $("#q").autoGrow(40);
  
  $('#ngramForm').on({
    'ajax:error': function() {
      alert("WHOOPS! Something went wrong, try again")
    },
    'submit': function() {
      $("#articleSummaries").empty()
    },
    'ajax:success': function(xhr, data, status) {
      var $this, query, filename, title;
      $this = $(this);
      
      if (data["tagline"]) {
        var tag = $("#tagline .rotating")
        if (tag.hasClass("keep")) {
          tag.removeClass("keep");
        } else {
          tag.html(data["tagline"]);
        }
      }
      
      query = $this.find('#q').val();
      smooth = data["smoothing"]
      $this.find('#s').val(smooth);
      filename = ('Jeopardy! N-Grams' + '_' + query).replace(/[^A-Za-z0-9_]/g, '').substr(0, 40);
      
      var series, term, terms, _i, _len;
      if (data["error"]) {
        alert(data["error"]);
        return false;
      } else if (!data) {
        alert("Something went wrong, try again");
        return false;
      }
      
      if (history && history.pushState && !$this.hasClass("noPush")) {
        popstateReady = true;
        window.history.pushState(null, null, "/ngrams/?q=" + encodeURIComponent(query) + "&s=" + smooth);
      }
      
      $this.removeClass("noPush")
      
      terms = getKeys(data["terms"]);
      series = [];
      for (_i = 0, _len = terms.length; _i < _len; _i++) {
        term = terms[_i];
        series.push({
          name: term,
          data: data["terms"][term],
          pointStart: data["years"][0]
        });
      }
      
      title = terms.join(", ")
      
      $('#ngramContainer').highcharts({
        tooltip: {
          enabled: true,
          shared: true,
          formatter: function() {
            var s = '<b>' + this.x + '</b>'
            
            var sortedPoints = this.points.sort(function(a, b) {
              return ((a.y < b.y) ? 1 : ((a.y > b.y) ? -1 : 0));
            });
            
            $.each(sortedPoints, function(i, point) {
              s += '<br/><span style="color: ' + point["series"]["color"] + '">' +
                    point.series.name + ':</span> ' +
                    Math.round(100 * point.y * 100000) / 100000 + '%'
            });
            return s;
          }
        },
        xAxis: {
          categories: data["years"],
          tickInterval: 5,
          tickWidth: 0,
          gridLineWidth: 1,
          tickmarkPlacement: 'on'
        },
        yAxis: {
          min: 0,
          plotLines: [
            {
              value: 0,
              width: 1,
              color: '#808080'
            }
          ],
          labels: {
            formatter: function() {
              return Math.round(100 * 1000000000000 * this.value) / 1000000000000 + "%";
            }
          },
          title: {
            text: "Jeopardy! Question Frequency"
          }
        },
        title: {
          text: title,
          style: {
            fontSize: '18px',
            lineHeight: '18px'
          },
          margin: 15
        },
        subtitle: {
          text: "Smoothing Factor " + data["smoothing"]
        },
        series: series,
        legend: {
          layout: "horizontal",
          align: "center",
          verticalAlign: "bottom",
          borderWidth: 0,
          itemStyle: {
            fontSize: '14px'
          }
        },
        plotOptions: {
          series: {
            animation: false,
            marker: {
              enabled: false
            }
          }
        },
        exporting: {
          filename: filename,
          buttons: {
            contextButton: {
              symbol: false,
              text: 'Download Graph',
              onclick: function() {
                this.exportChart();
              }
            }
          }
        },
        credits: {
          text: "James Somers",
          href: "http://jsomers.net"
        }
      });
      
      $.get("/ngrams/search", { q: query }, function(data) {
        $("#articleSummaries").html(data)
      });
      
      setupTweetButton();
    }
  });
  
  $("#articleSummaries").on("click", ".moreArticles", function() {
    var $this = $(this).closest("#articleSummaries")
    var query = $('#ngramForm #q').val();
    
    $.get("/ngrams/search", { q: query }, function(data) {
      $this.html(data)
    });
  });
  
  $('#randomSearch, .rotating, .refreshTagline').on({
    click: function(e) {
      e.preventDefault();
      
      $.get("/ngrams/random", function(data) {
        $("#ngramForm #q").val(data["raw"]);
        $("#ngramForm #q").autoGrow(40)
        $("#ngramForm #s").val(data["smoothing"]);
        $("#ngramForm").submit();
      });
      return false;
    }
  });
  
  if (!$('#blank').val()) {
    if ($('#q').val()) {
      $('#ngramSubmit').submit();
    } else {
      $("#randomSearch").click();
    }
  }
  
  $(".smoothing").popover({
    trigger: 'hover',
    placement: 'bottom',
    content: 'A smoothing value of 1 means that the data shown for 1990 will be the average of 1989, 1990, and 1991. In general you should use higher values of smoothing when you search for less common terms. Set smoothing to 0 if you want the raw data'
  });
  
  $(".comma-separated").popover({
    trigger: 'hover',
    placement: 'bottom',
    content: "Searches are not case sensitive, and punctuation is removed automatically. You can use '+' and '/' along with parentheses to do more advanced queries. See the 'About' page for more info"
  });
  
  $("#exportGraph").on({
    click: function() {
      $("#ngramContainer .highcharts-button").click();
    }
  });
  
  if (history && history.pushState) {
    $(window).on("popstate", function() {
      // if (!popstateReady) { return false; }
      if (!getParameterByName("q")) return false
      
      $("#q").val(getParameterByName("q"));
      $("#q").autoGrow(40);
      $("#s").val(getParameterByName("s"));
      
      $("#ngramForm").addClass("noPush")
      $("#ngramSubmit").submit();
    });
  }
});