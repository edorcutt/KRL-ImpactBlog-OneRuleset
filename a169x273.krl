ruleset a169x273 {
    meta {
        name "KRL-ImpactBlog-OneRuleset"
    	description <<
            Kynetx Impact 2011 Blog demo with one Ruleset
    http://www.lobosllc.com/demo/impactblog/blogone.html
    
        Application Variables:
            ent:BlogRoll{}
    >>
    author "Ed Orcutt, LOBOSLLC"
    logging on
    }
    
    global {
        BlogRollInit = { '2011-03-29T15:22:20-00:00' : {
            'author' :'Ed Orcutt',
            'title'  :'First Post',
            'time'   :'2011-03-29T15:22:20-06:00',
            'body'   :'This is a sample blog post.'
        }};
    }

    // ------------------------------------------------------------------------
    // Debug: Just used to clear the blog post data 
    rule ImpactBlog_Reset is active {
        select when pageview ".*"
        { noop(); }
        always {
            clear ent:BlogRoll;
        }
    }
    
    rule ImpactBlog_BlogRoll_init {
        select when pageview ".*"
        pre {
            BlogRoll = ent:BlogRoll || BlogRollInit;
        }
        { noop(); }
        fired {
            set ent:BlogRoll BlogRoll;
        }
    }
    
    // ------------------------------------------------------------------------
    // Don't run twice! Hack
    
    rule KRUD_CodeMonkey is inactive {
      select when pageview ".*"
        pre {
          tagMonkey = "<div id='CodeMonkey' style='display:none;'>CodeMonkey</div>";
          CodeMonkey = 0;
        }
        {
          emit <|
            CodeMonkey = $KOBJ("#CodeMonkey").length;
            // console.log("CodeMonkey: ", CodeMonkey);
            if (!CodeMonkey) {
              $KOBJ("body").append(tagMonkey);
              app = KOBJ.get_application("a169x273");
              app.raise_event("impactblog_init", {});
            }
          |>;
          noop();
        }
        always {
          last
        }
    }

    // ------------------------------------------------------------------------
    rule ImpactBlog_Init {
        select when pageview ".*"
        // select when web impactblog_init
        {
            // notify("ImpactBlog", "Init running ...") with sticky = true;
            emit <| $K("#siteNavPost").show(); |>;
            watch("#siteNavHome",  "click");
            watch("#siteNavAbout", "click");
            watch("#siteNavPost", "click");
            watch("#blogform", "submit");
        }
        fired {
            raise explicit event blog_showall
        }
    }
    
    // ------------------------------------------------------------------------
    rule ImpactBlog_SiteNav_Home {
        select when click "#siteNavHome"
        {
            replace_inner("div#blogroll", "");
            emit <|
                $K(".dynacontainer").hide('slow');
                $K("#dynahome").show('slow');
            |>;
        }
        fired {
            raise explicit event blog_showall
        }
    }
    
    // ------------------------------------------------------------------------
    rule ImpactBlog_Blog_ShowAll {
        select when explicit blog_showall
        foreach ent:BlogRoll setting (postKey,postHash)
        pre {
            postAuthor = postHash.pick("$.author");
            postTitle  = postHash.pick("$.title");
            postBody   = postHash.pick("$.body");
            postTime   = postHash.pick("$.time");
            postArticle = <<
                <article class="post">
                  <header>
                    <h3>#{postTitle}</h3>
                    <p class="postinfo">Published on <time>#{postTime}</time></p>
                  </header>
                  <p>#{postBody}</p>
                  <footer>
                    <span class="author">#{postAuthor}</span>
                  </footer>
                </article>
            >>;
        }
        {
            // notify("author: ", postAuthor) with sticky = true;
            prepend("div#blogroll", postArticle);
        }
    }
    
    // ------------------------------------------------------------------------
    rule ImpactBlog_SiteNav_About {
        select when click "#siteNavAbout"
        {
            emit <|
                $K(".dynacontainer").hide('slow');
                $K("#dynaabout").show('slow');
            |>;
        }
    }
    
    // ------------------------------------------------------------------------
    rule ImpactBlog_SiteNav_Post {
        select when click "#siteNavPost"
        {
            emit <|
                $K(".dynacontainer").hide('slow');
                $K("#dynapost").show('slow');
            |>;
        }
    }
    
    // ------------------------------------------------------------------------
    rule ImpactBlog_Blog_Post_Submit {
        select when submit "#blogform"
        pre {
            postAuthor = page:param("postauthor");
            postTitle = page:param("posttitle");
            postBody = page:param("postbody");
            postTime = time:now({"tz":"America/Denver"});
            postHash = { postTime : {
                "author" : postAuthor,
                "title"  : postTitle,
                "body"   : postBody,
                "time"   : postTime
            }};
            BlogRoll = ent:BlogRoll || {};
            BlogRoll = BlogRoll.put(postHash);
        }
        {
            // notify("author: " + postAuthor, "title: " + postTitle) with sticky = true;
            // notify("body:", postBody) with sticky = true;
            noop();
        }
        fired {
            set ent:BlogRoll BlogRoll;
        }
    }
}
