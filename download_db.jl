#!/usr/bin/env julia

## @file download_db.jl
#
#
## @author Enrico Milanese <enrico.milanese@whoi.edu>
#
## @date Thu 06 Nov 2025

##########################################################################
using HTTP
using ProgressMeter
using ZipFile
using ArgParse
using Logging

# Suppress INFO level logs from HTTP.jl downloads
Logging.disable_logging(Logging.Info)

##########################################################################
# Dictionary of URLs
const URLS = Dict(
    # stable versions
    "0007_PHY_CROCOLAKE-QC-MERGED" => "https://whoi-my.sharepoint.com/:u:/g/personal/enrico_milanese_whoi_edu/Eer0i-G9PGFEqQFEld4-C_sBrj8cUZTGggWLITXvDLenMA?e=121XEf&download=1",
    "0007_BGC_CROCOLAKE-QC-MERGED" => "https://whoi-my.sharepoint.com/:u:/g/personal/enrico_milanese_whoi_edu/EbaJJN6r0EFLrhpy3Z7peYUBWr3uQxg0MSzVBBZnnJgQeg?e=6lYFX0&download=1",
    "1003_PHY_ARGO-QC" => "https://whoi-my.sharepoint.com/:u:/g/personal/enrico_milanese_whoi_edu/EU27jRjY_llJlIsXNimqYzYBYOZmWnszAwtjTGmqOApI7g?e=OKcY0P&download=1",
    "1003_BGC_ARGO-QC" => "https://whoi-my.sharepoint.com/:u:/g/personal/enrico_milanese_whoi_edu/ETgmVncDinFOjOFe1iKTd0ABY98L67cxfhUGoPWtPnCjxQ?e=riUvGd&download=1",
    "1011_PHY_ARGO-CLOUD" => "https://whoi-my.sharepoint.com/:u:/g/personal/enrico_milanese_whoi_edu/ESqHZwCxTyBHt4_fJnrfdqwBmk-UBKG38yMLUZ2jOEWjqQ?e=33g5zK&download=1",
    "1011_BGC_ARGO-CLOUD" => "https://whoi-my.sharepoint.com/:u:/g/personal/enrico_milanese_whoi_edu/EcI3tSLsly5Lv33VMd7H2vgBgj8JEX0bsd5gfQaADv2Tkw?e=dR0ITr&download=1",
    # older dev versions
    "0006_PHY_CROCOLAKE-QC-MERGED-DEV" => "https://whoi-my.sharepoint.com/:u:/g/personal/enrico_milanese_whoi_edu/ETVsmC-RKnlIpH_cWf1fSHcBCfeAPGT9QOCv7Qxxrbt4Mg?e=oODdbu&download=1",
    "0006_BGC_CROCOLAKE-QC-MERGED-DEV" => "https://whoi-my.sharepoint.com/:u:/g/personal/enrico_milanese_whoi_edu/EYu01zZNqjJLi9ep8eM3SNwBAG98weAgQWqlmNbYeuncRg?e=ie04C4&download=1",
    "1002_PHY_ARGO-QC-DEV" => "https://whoi-my.sharepoint.com/:u:/g/personal/enrico_milanese_whoi_edu/Ebme_Sr3np9CtEpcTZAnLPUBGY1rI9WvabYRtv9IAeFprg?e=Pb81Cd&download=1",
    "1002_BGC_ARGO-QC-DEV" => "https://whoi-my.sharepoint.com/:u:/g/personal/enrico_milanese_whoi_edu/EYs1amvXcH9Ml_qTXzdQNNYBYWPMonx8mcA6Hd2sXqNItw?e=FNEiaq&download=1",
    "1010_PHY_ARGO-CLOUD-DEV" => "https://whoi-my.sharepoint.com/:u:/g/personal/enrico_milanese_whoi_edu/EdC3MXJfZQ5Ku1uMBpoizpUBFHzED10M9PmY9qte7lpIqw?e=wcfl1q&download=1",
    "1010_BGC_ARGO-CLOUD-DEV" => "https://whoi-my.sharepoint.com/:u:/g/personal/enrico_milanese_whoi_edu/EYs1amvXcH9Ml_qTXzdQNNYBYWPMonx8mcA6Hd2sXqNItw?e=6gvkbu&download=1"
)

#------------------------------------------------------------------------------#
function get_db_codename(db_name::String, db_type::String, qc::Bool, dev::Bool=false)
    db_name = uppercase(db_name)
    db_type = uppercase(db_type)
    
    if db_name == "CROCOLAKE"
        if !qc
            error("CrocoLake database available only with QC.")
        end
        if db_type == "PHY"
            codename = "0007_PHY_CROCOLAKE-QC-MERGED"
        elseif db_type == "BGC"
            codename = "0007_BGC_CROCOLAKE-QC-MERGED"
        else
            error("Invalid database type. Must be 'PHY' or 'BGC'.")
        end
    elseif db_name == "ARGO"
        if db_type == "PHY"
            codename = qc ? "1003_PHY_ARGO-QC" : "1011_PHY_ARGO-CLOUD"
        elseif db_type == "BGC"
            codename = qc ? "1003_BGC_ARGO-QC" : "1011_BGC_ARGO-CLOUD"
        else
            error("Invalid database type. Must be 'PHY' or 'BGC'.")
        end
    else
        error("Invalid database name. Must be 'CROCOLAKE' or 'ARGO'.")
    end
    
    return dev ? codename * "-DEV" : codename
end

#------------------------------------------------------------------------------#
function download_file(url::String, local_filename::String)
    """Download a file from a URL and save it locally."""
    
    println("Downloading to: $local_filename")
    println("This may take a while for large files...")
    
    try
        # Use HTTP.download which handles redirects properly
        HTTP.download(url, local_filename)
        
        # Get file size
        filesize = stat(local_filename).size
        println("Download complete! File size: $(round(filesize/1024/1024, digits=2)) MB")
    catch e
        println("An error occurred: $e")
        rethrow(e)
    end
end

#------------------------------------------------------------------------------#
function unzip_file(zip_filepath::String, extract_to::String)
    """Unzip a file to a specified directory."""
    
    println("Extracting to: $extract_to")
    
    # Use system unzip command for better compatibility with large ZIP64 files
    try
        run(`unzip -q -o $zip_filepath -d $extract_to`)
        println("Extraction complete!")
    catch e
        println("System unzip failed, trying Julia ZipFile package...")
        # Fallback to ZipFile.jl if system unzip is not available
        try
            reader = ZipFile.Reader(zip_filepath)
            
            for file in reader.files
                filepath = joinpath(extract_to, file.name)
                
                # Create directory structure if needed
                mkpath(dirname(filepath))
                
                # Extract file
                if !endswith(file.name, "/")
                    open(filepath, "w") do f
                        write(f, read(file))
                    end
                end
            end
            
            close(reader)
            println("Extraction complete!")
        catch e2
            println("An error occurred during extraction: $e2")
            rethrow(e2)
        end
    end
end

#------------------------------------------------------------------------------#
function parse_commandline()
    s = ArgParseSettings(
        description = "Script to download CrocoLake and Argo databases."
    )
    
    @add_arg_table! s begin
        "--db", "-d"
            help = "Name of database to download ('CrocoLake' or 'Argo')"
            required = true
        "--type", "-t"
            help = "Type of variables ('PHY' or 'BGC')"
            required = true
        "--qc"
            help = "Only best quality measurements are downloaded (default)"
            action = :store_true
        "--noqc"
            help = "No QC is performed"
            action = :store_true
        "--destination"
            help = "Destination folder to download data to (default: ./CrocoLake/)"
            default = "./CrocoLake"
    end
    
    return parse_args(s)
end

#------------------------------------------------------------------------------#
function main()
    args = parse_commandline()
    
    # Handle QC flags
    if args["qc"] && args["noqc"]
        error("Cannot specify both --qc and --noqc")
    end
    
    qc = args["noqc"] ? false : true
    
    destination = args["destination"]
    db_type = args["type"]
    db_name = args["db"]
    
    db_codename = get_db_codename(db_name, db_type, qc)
    
    # Ensure destination ends with "/"
    if !endswith(destination, "/")
        destination *= "/"
    end
    
    extract_to = destination * db_codename * "/"
    mkpath(extract_to)
    
    local_zipfile = extract_to * db_codename * ".zip"
    
    # Download the dataset
    println("Downloading dataset $db_name, type $db_type (identifier: $db_codename)...")
    download_file(URLS[db_codename], local_zipfile)
    
    # Unzip the dataset
    println("Unzipping dataset...")
    unzip_file(local_zipfile, extract_to)
    
    # Clean up
    println("Cleaning up...")
    rm(local_zipfile)
    
    println("Database setup complete.")
end

##########################################################################
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
