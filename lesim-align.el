;;; lesim-align.el --- Functions to align lesim buffers -*- lexical-binding: t; -*-

;; Copyright (C) 2023 Stefano Ghirlanda

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Functions to align lesim buffers.

;;; Code:

(require 'lesim-type)
(require 'lesim-locate)

(defun lesim--align-phase ()
  "Align phase block at point.
If point is not in a phase block, do nothing."
  (let ((region (lesim--phase-region-at-point)))
    (when region
      (save-excursion
        (goto-char (nth 0 region))
        (forward-line) ; skip @phase line
        (let ((beg (point))
              (end (nth 1 region))
              (indent-tabs-mode nil))
          ;; standardize spaces after | and hide resulting messages:
          (while (re-search-forward "|\\s-*" end t)
            (replace-match "| "))
          (message "")
          ;; align line id and stimulus:
          (align-regexp beg end "\\(\\s-+\\)\\s-" 1 1 nil)
          ;; align | clauses:
          (align-regexp beg end "\\(\\s-*\\)|" 1 1 t))))))
          ;; align comments
          ;; (goto-char (nth 0 region))
          ;; (while (re-search-forward "^\\s-*\\(#+\\s-+\\)" end t)
          ;;   (replace-match "# ")))))))

(defun lesim--align-parameters ()
  "Align parameter block at point.
If point is not in a parameter block, do nothing."
  (save-excursion
    (let ((search-start (point))
          (assign-re  (concat "^\\(\\s-*" lesim--name-re "\\s-*=.+\\|#.*\\|[z-a]\\)$"))
          (continue t))
      ;; search backward, stop when we found non-comment non-empty
      ;; line that is not a parameter assignment:
      (while (and continue (re-search-backward assign-re (point-min) t))
        (unless (string-match-p (concat "'\\s-*" lesim--name-re "\\s-*=") (match-string 1))
          (setq continue nil)))
      (let ((beg (match-beginning 0))
            (indent-tabs-mode nil)
            (continue t))
        (while (and continue (re-search-forward assign-re (point-max) t))
          (unless (string-match-p (concat "'\\s-*" lesim--name-re "\\s-*=") (match-string 1))
            (setq continue nil)))
        (let ((end (match-end 0)))
          (when (and (<= search-start end) (>= search-start beg))
            ;; standardize spaces after = and ,
            (goto-char beg)
            (while (re-search-forward "\\([=,]\\)[ \t]+" end t)
              (replace-match "\\1 "))
            ;; hide replace-regexp message:
            (message "")
            (align-regexp beg
                          end
                          "\\(\\s-*\\)="
                          1
                          1
                          t)))))))

(defun lesim-align ()
  "Align phase and parameters blocks at point."
  (interactive)
  (or (lesim--align-phase)
      (lesim--align-parameters)))

(provide 'lesim-align)
;;; lesim-align.el ends here
