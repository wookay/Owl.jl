# override Documenter.jl/src/Writers/HTMLWriter.jl

import Documenter: Anchors, Builder, Documents, Expanders, Formats, Documenter, Utilities, Writers
import Documenter.Utilities.DOM: DOM, Tag, @tags
import Documenter.Writers.HTMLWriter: pagetitle, domify, open_output
import Documenter.Writers.HTMLWriter: navhref, relhref
import Documenter.Writers.HTMLWriter: mdconvert, mdflatten
import Documenter.Writers.HTMLWriter: getpage, get_url
import Documenter.Writers.HTMLWriter: render_head, render_topbar, render_navmenu, render_article
import Documenter.Writers.HTMLWriter: normalize_css, google_fonts, fontawesome_css, highlightjs_css
import Documenter.Writers.HTMLWriter: analytics_script, requirejs_cdn, asset_links

function Documenter.Writers.HTMLWriter.render_head(ctx, navnode)
    @tags head meta link script title style
    src = get_url(ctx, navnode)

    page_title = "$(mdflatten(pagetitle(ctx, navnode))) · $(ctx.doc.user.sitename)"
    css_links = [
        normalize_css,
        google_fonts,
        fontawesome_css,
        highlightjs_css,
    ]
    head(
        meta[:charset=>"UTF-8"],
        meta[:name => "viewport", :content => "width=device-width, initial-scale=1.0"],
        title(page_title),

        Tag(Symbol("#RAW#"))("""
<script async src="//pagead2.googlesyndication.com/pagead/js/adsbygoogle.js"></script>
<script>
     (adsbygoogle = window.adsbygoogle || []).push({
          google_ad_client: "ca-pub-6977995344550016",
          enable_page_level_ads: true
     });
</script>
"""),

        # Stylesheets.
        map(css_links) do each
            link[:href => each, :rel => "stylesheet", :type => "text/css"]
        end,

        script("documenterBaseURL=\"$(relhref(src, "."))\""),
        script[
            :src => requirejs_cdn,
            Symbol("data-main") => relhref(src, ctx.documenter_js)
        ],

        script[:src => relhref(src, "siteinfo.js")],
        script[:src => relhref(src, "../versions.js")],

        # Custom user-provided assets.
        asset_links(src, ctx.local_assets),

        link[:href => relhref(src, "assets/custom.css"), :rel => "stylesheet", :type => "text/css"],

        # 단어 word break
        script[:src => "assets/jquery-1.8.3.min.js"],
        script[:src => "assets/jquery.word-break-keep-all.min.js"],
        script("\$(document).ready(function() { \$('p').wordBreakKeepAll(); });")
    )
end

function Documenter.Writers.HTMLWriter.render_page(ctx, navnode)
    @tags html body

    page = getpage(ctx, navnode)

    head = render_head(ctx, navnode)
    navmenu = render_navmenu(ctx, navnode)
    article = render_article(ctx, navnode)

    htmldoc = DOM.HTMLDocument(
        html[:lang=>"ko"](
            head,
            body(navmenu, article)
        )
    )

    open_output(ctx, navnode) do io
        print(io, htmldoc)
    end
end

function Documenter.Writers.HTMLWriter.render_article(ctx, navnode)
    @tags article header footer nav ul li hr span a

    header_links = map(Documents.navpath(navnode)) do nn
        title = mdconvert(pagetitle(ctx, nn); droplinks=true)
        nn.page === nothing ? li(title) : li(a[:href => navhref(ctx, nn, navnode)](title))
    end

    topnav = nav(ul(header_links))

    # Set the logo and name for the "Edit on.." button. We assume GitHub as a host.
    host = "GitHub"
    logo = "\uf09b"

    host_type = Utilities.repo_host_from_url(ctx.doc.user.repo)
    if host_type == Utilities.RepoGitlab
        host = "GitLab"
        logo = "\uf296"
    elseif host_type == Utilities.RepoBitbucket
        host = "BitBucket"
        logo = "\uf171"
    end

    if !ctx.doc.user.html_disable_git
        url = Utilities.url(ctx.doc.user.repo, getpage(ctx, navnode).source, commit=ctx.doc.user.html_edit_branch)
        if url !== nothing
            push!(topnav.nodes, a[".edit-page", :href => url](span[".fa"](logo), " Edit on $host"))
        end
    end
    art_header = header(topnav, hr(), render_topbar(ctx, navnode))

    # build the footer with nav links
    art_footer = footer(hr())
    if navnode.prev !== nothing
        direction = span[".direction"]("이전글") # Previous
        title = span[".title"](mdconvert(pagetitle(ctx, navnode.prev); droplinks=true))
        link = a[".previous", :href => navhref(ctx, navnode.prev, navnode)](direction, title)
        push!(art_footer.nodes, link)
    end

    if navnode.next !== nothing
        direction = span[".direction"]("다음글") # Next
        title = span[".title"](mdconvert(pagetitle(ctx, navnode.next); droplinks=true))
        link = a[".next", :href => navhref(ctx, navnode.next, navnode)](direction, title)
        push!(art_footer.nodes, link)
    end

    pagenodes = domify(ctx, navnode)
    article["#docs"](art_header, pagenodes, art_footer)
end
