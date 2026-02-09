// MARK: - Data+Gzip.swift
// PURPOSE: Gzip decompression for bundled compressed databases
// DEPENDENCIES: Foundation, zlib

import Foundation
import Compression

extension Data {
    /// Decompress gzip-compressed data
    func gunzip() -> Data? {
        // Gzip header is at least 10 bytes
        guard self.count > 10 else { return nil }

        // Verify gzip magic number (0x1f 0x8b)
        guard self[0] == 0x1f, self[1] == 0x8b else { return nil }

        // Use Apple's Compression framework with ZLIB (handles gzip)
        // Strip the 10-byte gzip header and 8-byte footer
        let headerSize = gzipHeaderSize()
        guard headerSize < self.count - 8 else { return nil }

        let compressedData = self.subdata(in: headerSize..<(self.count - 8))

        // Allocate output buffer (estimate 4x expansion for text-heavy SQLite)
        let estimatedSize = self.count * 6
        var outputData = Data(count: estimatedSize)
        var actualSize = 0

        let result = compressedData.withUnsafeBytes { (srcPtr: UnsafeRawBufferPointer) -> Bool in
            outputData.withUnsafeMutableBytes { (dstPtr: UnsafeMutableRawBufferPointer) -> Bool in
                guard let src = srcPtr.baseAddress, let dst = dstPtr.baseAddress else { return false }

                let size = compression_decode_buffer(
                    dst.assumingMemoryBound(to: UInt8.self),
                    estimatedSize,
                    src.assumingMemoryBound(to: UInt8.self),
                    compressedData.count,
                    nil,
                    COMPRESSION_ZLIB
                )

                if size > 0 {
                    actualSize = size
                    return true
                }
                return false
            }
        }

        guard result else { return nil }
        outputData.count = actualSize
        return outputData
    }

    /// Calculate the size of the gzip header (variable due to optional fields)
    private func gzipHeaderSize() -> Int {
        var offset = 10 // Minimum gzip header
        let flags = self[3]

        // FEXTRA
        if flags & 0x04 != 0, offset + 2 < self.count {
            let extraLen = Int(self[offset]) | (Int(self[offset + 1]) << 8)
            offset += 2 + extraLen
        }
        // FNAME
        if flags & 0x08 != 0 {
            while offset < self.count, self[offset] != 0 { offset += 1 }
            offset += 1
        }
        // FCOMMENT
        if flags & 0x10 != 0 {
            while offset < self.count, self[offset] != 0 { offset += 1 }
            offset += 1
        }
        // FHCRC
        if flags & 0x02 != 0 { offset += 2 }

        return offset
    }
}
