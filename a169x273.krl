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
        // --------------------------------------------
        // initial sample blog post

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
    
    // ------------------------------------------------------------------------
    // Initialize the blog post hash on the first run

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
    // Initialize the blog page when first run, attach watches to buttons

    rule ImpactBlog_Init {
        select when pageview ".*"
        {
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
    // Site Navigation button clicked: Home

    rule ImpactBlog_SiteNav_Home {
        select when click "#siteNavHome"
        {
            // flush any blog post displayed
            replace_inner("div#blogroll", "");

            // hide all panel, then show the home panel
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
    // Site Navigation button clicked: About

    rule ImpactBlog_SiteNav_About {
        select when click "#siteNavAbout"
        {
            // hide all panel, then show the about panel
            emit <|
                $K(".dynacontainer").hide('slow');
                $K("#dynaabout").show('slow');
            |>;
        }
    }
    
    // ------------------------------------------------------------------------
    // Site Navigation button clicked: Post

    rule ImpactBlog_SiteNav_Post {
        select when click "#siteNavPost"
        {
            // hide all panel, then show the post panel
            emit <|
                $K(".dynacontainer").hide('slow');
                $K("#dynapost").show('slow');
            |>;
        }
    }

    // ------------------------------------------------------------------------
    // Display all blog post in the Home panel

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
            prepend("div#blogroll", postArticle);
        }
    }
    
    // ------------------------------------------------------------------------
    // Save new blog post in hash

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
        { noop(); }
        fired {
            set ent:BlogRoll BlogRoll;
        }
    }
}
