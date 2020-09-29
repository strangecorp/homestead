# Strange Homestead

A fork of the original Laravel Homestead project containing addition business level requirements.

## Provisioning the Homestead VM

1. Checkout the project in the folder which contains your local sites e.g.e ~/Workspace   
``` cd ~/Workspace && git clone https://github.com/strangecorp/homestead.git```

2. Create the guest machine  
```vagrant up```

## Updating the Homestead VM

1. Ensure you are in the directory which contains the running VM *e.g. ~/Workspace/homestead*

2. Stop the VM   
```vagrant halt```

3. Destroy the VM deleting all resources created during the creation process  
```vagrant destroy```

4. Open your fork of the repository.

5. Click the compare button.

   *This will open a page titled Comparing Changes and if you look carefully you'll have jumped to the upstream version of the repository. If you were to do a regular pull request then this makes sense as you'd be bringing your changes into the upstream version. But in this case we want to flip the direction and pull changes from the original version to our fork.*

6. Change the base fork to your repository

7. You're now back to your fork but you've also asked to compare two identical repositories so GitHub thinks you care about branches not forks. Click on compare across forks to get back your base fork option.

8. Change the head fork to the upstream (original) repository

9. You'll see one of two options:   
    * "There isn’t anything to compare" This means you're up to date and you don't have to do anything. Phew.
    * A list of commits. These are the changes that have happened in the repository since you forked your version. Go to step 10*

10. Create a pull request

    *Note that this pull request is to you! So you can confirm that it's ok and merge it when necessary. And if there are any merge conflicts then it's up to you to figure out what's gone wrong and sort them out.*
        
11. Re-provision the guest machine   
```vagrant reload --provision```

## Xdebug

If you wish to enable Xdebug for local development

1. SSH into the virtual machine from the homestead project root  
```vagrant ssh```

2. Enable xdebug  
```sudo phpenmod xdebug```

3. Locate the xdebug.ini file  
```php --ini | grep xdebug```

4. Edit the returned file adding the following lines:

    ```zend_extension=xdebug.so  
    xdebug.remote_enable = 1  
    xdebug.remote_autostart = 1  
    xdebug.remote_host = 10.0.2.2  
    xdebug.remote_port = 9000  
    xdebug.max_nesting_level = 512    

5. Restart PHP FPM   
```sudo systemctl restart php7.VERSION-fpm```   
*Replace version with the version of PHP the project is running e.g* ```php7.4```

6. Follow instructions to configure PHPSTORM for Xdebug development
