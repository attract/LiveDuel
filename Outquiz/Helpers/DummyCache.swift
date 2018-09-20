//
//  DummyCache.swift
//  Outquiz
//
//  Created by Vasily Evreinov on 24.04.2018.
//  Copyright © 2018 Vasily Evreinov. All rights reserved.
//

import Kingfisher

class DummyCache: ImageCache
{
    // MARK: - Store & Remove
    
    /**
     Store an image to cache. It will be saved to both memory and disk. It is an async operation.
     
     - parameter image:             The image to be stored.
     - parameter original:          The original data of the image.
     Kingfisher will use it to check the format of the image and optimize cache size on disk.
     If `nil` is supplied, the image data will be saved as a normalized PNG file.
     It is strongly suggested to supply it whenever possible, to get a better performance and disk usage.
     - parameter key:               Key for the image.
     - parameter identifier:        The identifier of processor used. If you are using a processor for the image, pass the identifier of
     processor to it.
     This identifier will be used to generate a corresponding key for the combination of `key` and processor.
     - parameter toDisk:            Whether this image should be cached to disk or not. If false, the image will be only cached in memory.
     - parameter completionHandler: Called when store operation completes.
     */
    open override func store(_ image: Image,
                    original: Data? = nil,
                    forKey key: String,
                    processorIdentifier identifier: String = "",
                    cacheSerializer serializer: CacheSerializer = DefaultCacheSerializer.default,
                    toDisk: Bool = true,
                    completionHandler: (() -> Void)? = nil)
    {
        func callHandlerInMainQueue() {
            if let handler = completionHandler {
                DispatchQueue.main.async {
                    handler()
                }
            }
        }
        callHandlerInMainQueue()
    }
}
