# PSCopyFileAsync

This class allows for asynchronous file copying and progress updates.

# Getting Started

The class is called using the new constructor with a source and destination

```$FileCopy = [CopyFile]::new($Source, $Destination)```

To get progress you can use the scriptproperty progess which will update the objects progress then return the value

```$FileCopy.progress```

# References
https://stackoverflow.com/questions/2434133/progress-during-large-file-copy-copy-item-write-progress

