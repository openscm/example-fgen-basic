"""
Formatting support

I.e. display of wrapped Fortran derived types in a nice way
"""

from __future__ import annotations

from collections.abc import Iterable
from typing import TYPE_CHECKING, Any

from example_fgen_basic.pyfgen_runtime.exceptions import UnallocatedMemoryError

# Might be needed for Python 3.9
# from typing_extensions import Concatenate, ParamSpec
if TYPE_CHECKING:
    from example_fgen_basic.pyfgen_runtime.base_finalisable import (
        FinalisableWrapperBase,
    )


def get_attribute_str_value(instance: FinalisableWrapperBase, attribute: str) -> str:
    """
    Get the string version of an attribute's value

    Parameters
    ----------
    instance
        Instance from which to get the attribute

    attribute
        Attribute for which to get the value

    Returns
    -------
        String version of the attribute's value, with graceful handling of errors.
    """
    try:
        return f"{attribute}={getattr(instance, attribute)}"
    except UnallocatedMemoryError:
        # TODO: change this when we move to better error handling
        return f"{attribute} is unallocated"


def to_str(instance: FinalisableWrapperBase, exposed_attributes: Iterable[str]) -> str:
    """
    Convert an instance to its string representation

    Parameters
    ----------
    instance
        Instance to convert

    exposed_attributes
        Attributes from Fortran that the instance exposes

    Returns
    -------
        String representation of the instance
    """
    if not instance.initialized:
        return f"Uninitialised {instance!r}"

    if not exposed_attributes:
        return repr(instance)

    attribute_values = [
        get_attribute_str_value(instance, v) for v in exposed_attributes
    ]

    return f"{repr(instance)[:-1]}, {', '.join(attribute_values)})"


def to_pretty(
    instance: FinalisableWrapperBase,
    exposed_attributes: Iterable[str],
    p: Any,
    cycle: bool,
    indent: int = 4,
) -> None:
    """
    Pretty-print an instance

    Parameters
    ----------
    instance
        Instance to convert

    exposed_attributes
        Attributes from Fortran that the instance exposes

    p
        Pretty printing object

    cycle
        Whether the pretty printer has detected a cycle or not.

    indent
        Indent to apply to the pretty printing group
    """
    if not instance.initialized:
        p.text(str(instance))
        return

    if not exposed_attributes:
        p.text(str(instance))
        return

    with p.group(indent, f"{repr(instance)[:-1]}", ")"):
        for att in exposed_attributes:
            p.text(",")
            p.breakable()

            p.text(get_attribute_str_value(instance, att))


def add_attribute_row(
    attribute_name: str, attribute_value: str, attribute_rows: list[str]
) -> list[str]:
    """
    Add a row for displaying an attribute's value to a list of rows

    Parameters
    ----------
    attribute_name
        Attribute's name

    attribute_value
        Attribute's value

    attribute_rows
        Existing attribute rows


    Returns
    -------
        Attribute rows, with the new row appended
    """
    attribute_rows.append(
        f"<tr><th>{attribute_name}</th><td style='text-align:left;'>{attribute_value}</td></tr>"  # noqa: E501
    )

    return attribute_rows


def to_html(instance: FinalisableWrapperBase, exposed_attributes: Iterable[str]) -> str:
    """
    Convert an instance to its html representation

    Parameters
    ----------
    instance
        Instance to convert

    exposed_attributes
        Attributes from Fortran that the instance exposes

    Returns
    -------
        HTML representation of the instance
    """
    if not instance.initialized:
        return str(instance)

    if not exposed_attributes:
        return str(instance)

    instance_class_name = repr(instance).split("(")[0]

    attribute_rows: list[str] = []
    for att in exposed_attributes:
        try:
            att_val = getattr(instance, att)
        except UnallocatedMemoryError:
            # TODO: change this when we move to better error handling
            att_val = "Unallocated"
            attribute_rows = add_attribute_row(att, att_val, attribute_rows)
            continue

        try:
            att_val = att_val._repr_html_()
        except AttributeError:
            att_val = str(att_val)

        attribute_rows = add_attribute_row(att, att_val, attribute_rows)

    attribute_rows_for_table = "\n          ".join(attribute_rows)

    css_style = """.fgen-wrap {
  /*font-family: monospace;*/
  width: 540px;
}

.fgen-header {
  padding: 6px 0 6px 3px;
  border-bottom: solid 1px #777;
  color: #555;;
}

.fgen-header > div {
  display: inline;
  margin-top: 0;
  margin-bottom: 0;
}

.fgen-basefinalizable-cls,
.fgen-basefinalizable-instance-index {
  margin-left: 2px;
  margin-right: 10px;
}

.fgen-basefinalizable-cls {
  font-weight: bold;
  color: #000000;
}"""

    return "\n".join(
        [
            "<div>",
            "  <style>",
            f"{css_style}",
            "  </style>",
            "  <div class='fgen-wrap'>",
            "    <div class='fgen-header'>",
            f"      <div class='fgen-basefinalizable-cls'>{instance_class_name}</div>",
            f"        <div class='fgen-basefinalizable-instance-index'>instance_index={instance.instance_index}</div>",  # noqa: E501
            "        <table><tbody>",
            f"          {attribute_rows_for_table}",
            "        </tbody></table>",
            "    </div>",
            "  </div>",
            "</div>",
        ]
    )
