# https://github.com/VitalProject/PSCopyFileAsync
# refference https://stackoverflow.com/questions/2434133/progress-during-large-file-copy-copy-item-write-progress


Class CopyFile  : System.IDisposable
{
    hidden $_toFilePath
    hidden $_fromFilePath
    hidden $_progress
    hidden $_CopyJob

    #Begins copying file from source to destination
    CopyFile([string]$fromFile,[string]$toFile){
        if((Test-path $fromFile)){
            $this._progress=0
            $this._toFilePath=$toFile
            $this._fromFilePath=$fromFile
            if(!(Test-path (Split-Path $toFile))){
                New-Item -Path (Split-Path $toFile) -ItemType directory -force
            }
            
            $copyblock={
            param( [string]$from, [string]$to)
            $ffile = [io.file]::OpenRead($from)
            $tofile = [io.file]::OpenWrite($to)
                try {
                    [byte[]]$buff = new-object byte[] 4096
                    $total = $count = 0
                    do {
                        $count = $ffile.Read($buff, 0, $buff.Length)
                        $tofile.Write($buff, 0, $count)
                        $total += $count
                        if ($total % 1mb -eq 0) {
                        $progressbar=([int]($total/$ffile.Length* 100))

                        $progressbar
                        }
                    } while ($count -gt 0)
                }
                finally {
                    $progressbar=100
                    $progressbar        
                    $ffile.Dispose()
                    $tofile.Dispose() 
                }
            }
            $this._CopyJob=Start-Job -Name "copyFile_$(Split-path $fromFile -leaf)" -ScriptBlock $copyblock -ArgumentList $fromFile, $toFile

        }
        else{
            write-error "Invalid Source File"
            $this.Dispose()
        }

        $this.PSObject.Properties.Add(
            (New-Object PSScriptProperty 'progress', {$this.UpdateProgress();$this._progress})
        )
    }


    # updates the current progress
     hidden [void] UpdateProgress(){
        $progress=receive-job $this._CopyJob
        if($progress){
        $this._progress=$progress[$progress.count-1]
        }
     }
     
    # disposes of this class and cleans up job thread performs garbage collection
    # This occurs when the progess reaches 100%
     [void] Dispose(){
        
        if($this._progress -ne 100){
            $this._CopyJob | stop-Job -ErrorAction SilentlyContinue
            receive-job $this._CopyJob -AutoRemoveJob -wait -ErrorAction SilentlyContinue
            remove-item $this._toFilePath -Force -ErrorAction SilentlyContinue
        }
            $this._toFilePath =$null
            $this._fromFilePath=$null
            $this._progress=$null
            $this._CopyJob=$null
        $this.Dispose($true)

     }
     
     hidden [void] Dispose([bool]$disposable){
      if($disposable){
         foreach($prop in $this.psobject.properties.name){
               if($this."$prop" -ne $null){
                 if($this."$prop".GetType().BaseType.name -eq "Job"){
                    try{
                         $this."$prop" |stop-Job -ErrorAction SilentlyContinue
                         $this."$prop" |Remove-Job -force -ErrorAction SilentlyContinue
                     }finally{}
                 }
                 if($this."$prop".psobject.Methods.Item("dispose")){
                    $this."$prop".Dispose()
                 }
                 Set-Variable $this."$prop" -Value $null -ErrorAction SilentlyContinue
                }   
            $null=$this.psobject.Members.Remove("$prop") 
         }
         [System.GC]::SuppressFinalize($this)
         [System.GC]::Collect()
         }
     }


}

