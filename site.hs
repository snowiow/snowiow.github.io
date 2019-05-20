--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}

import Data.Monoid (mappend)
import Hakyll

--------------------------------------------------------------------------------
root :: String
root = "https://snow-dev.com"

main :: IO ()
main =
  hakyllWith config $ do
    match "CNAME" $ do
      route idRoute
      compile copyFileCompiler
    match "images/*" $ do
      route idRoute
      compile copyFileCompiler
    match "css/*" $ do
      route idRoute
      compile compressCssCompiler
    match "webfonts/*" $ do
      route idRoute
      compile copyFileCompiler
    match (fromList ["about.md", "impressum.md", "datenschutz.md"]) $ do
      route $ setExtension "html"
      compile $
        pandocCompiler >>=
        loadAndApplyTemplate "templates/default.html" defaultContext >>=
        relativizeUrls
    match "posts/*" $ do
      route $ setExtension "html"
      compile $
        pandocCompiler >>= loadAndApplyTemplate "templates/post.html" postCtx 
        >>= saveSnapshot "content"
        >>= loadAndApplyTemplate "templates/default.html" postCtx >>=
        relativizeUrls
    create ["archive.html"] $ do
      route idRoute
      compile $ do
        posts <- recentFirst =<< loadAll "posts/*"
        let archiveCtx =
              listField "posts" postCtx (return posts) `mappend`
              constField "title" "Archives" `mappend`
              defaultContext
        makeItem "" >>= loadAndApplyTemplate "templates/archive.html" archiveCtx >>=
          loadAndApplyTemplate "templates/default.html" archiveCtx >>=
          relativizeUrls
    match "index.html" $ do
      route idRoute
      compile $ do
        posts <- fmap (take 10) . recentFirst =<< loadAll "posts/*"
        let indexCtx =
              listField "posts" postCtx (return posts) `mappend` defaultContext
        getResourceBody >>= applyAsTemplate indexCtx >>=
          loadAndApplyTemplate "templates/default.html" indexCtx >>=
          relativizeUrls
    match "templates/*" $ compile templateBodyCompiler
    create ["sitemap.xml"] $ do
      route idRoute
      compile $
        -- load and sort the posts
       do
        posts <- recentFirst =<< loadAll "posts/*"
        singlePages <-
          loadAll (fromList ["about.md", "impressum.md", "datenschutz.md"])
        let pages = posts `mappend` singlePages
            sitemapCtx =
              constField "root" root `mappend`
              listField "pages" postCtx (return pages)
        makeItem "" >>= loadAndApplyTemplate "templates/sitemap.xml" sitemapCtx >>=
          relativizeUrls
    create ["rss.xml"] $ do
      route idRoute
      compile (feedCompiler renderRss)
    create ["atom.xml"] $ do
      route idRoute
      compile (feedCompiler renderAtom)

--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
  constField "root" root `mappend` dateField "date" "%Y-%m-%d" `mappend`
  defaultContext

feedCtx :: Context String
feedCtx = postCtx `mappend` bodyField "description"


config :: Configuration
config = defaultConfiguration {destinationDirectory = "docs"}

feedConfiguration :: FeedConfiguration
feedConfiguration = FeedConfiguration
  { feedTitle = "snow-dev.com"
  , feedDescription = "A blog about linux, vim, devops and various other tech topics"
  , feedAuthorName = "Marcel Patzwahl"
  , feedAuthorEmail = "marcel.patzwahl@posteo.de"
  , feedRoot = root
  }

type FeedRenderer =
    FeedConfiguration
    -> Context String
    -> [Item String]
    -> Compiler (Item String)

feedCompiler :: FeedRenderer -> Compiler (Item String)
feedCompiler renderer =
  renderer feedConfiguration feedCtx
    =<< recentFirst
    =<< loadAllSnapshots "posts/*" "content"
